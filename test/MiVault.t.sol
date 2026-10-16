// SPDX-License-Identifier: MIT
pragma solidity ^0.8.36;

import {Test} from "forge-std/Test.sol";
import {MiToken} from "../src/MiToken.sol";
import {MiVault} from "../src/MiVault.sol";

contract MiVaultTest is Test {
    MiToken token;
    MiVault vault;
    address alice;
    address bob;

    function setUp() public {
        token = new MiToken();
        vault = new MiVault(address(token));
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        // El test contract es el owner (lo viste en el trace), así que puede mintear directo
        token.mint(alice, 100);
        token.mint(bob, 100);

        // Cada uno tiene que aprobar al vault antes de depositar
        vm.prank(alice);
        token.approve(address(vault), 100);
        vm.prank(bob);
        token.approve(address(vault), 100);
    }

    function testDepositYieldWithdraw() public {
        // 1. Alice deposita 100
        //    - ¿quién tiene que llamar? (vm.prank)
        //    - verificá: sharesOf(alice) == 100, totalAssets() == 100
        vm.prank(alice);
        vault.deposit(100);
        assertEq(vault.sharesOf(alice), 100);
        assertEq(vault.totalAssets(), 100);

        // 2. Yield simulado: 50 MTK entran directo al vault, sin pasar por deposit()
        //    - ¿qué función de MiToken usás y hacia qué dirección?
        //    - verificá: totalAssets() == 150, totalShares() == 100
        vm.prank(token.owner());
        token.mint(address(vault), 50);
        vault.harvest(); // el test contract es owner del vault porque lo desplegó
        assertEq(vault.totalAssets(), 150);
        assertEq(vault.totalShares(), 100);

        // 3. Bob deposita 100
        //    - verificá: sharesOf(bob) == 66, totalShares() == 166, totalAssets() == 250
        vm.prank(bob);
        vault.deposit(100);
        assertEq(vault.sharesOf(bob), 66);
        assertEq(vault.totalShares(), 166);
        assertEq(vault.totalAssets(), 250);

        // 4. Alice retira sus 100 shares
        //    - verificá: token.balanceOf(alice) == 150, sharesOf(alice) == 0
        //    - verificá: totalAssets() == 100, totalShares() == 66
        vm.prank(alice);
        vault.withdraw(100);
        assertEq(token.balanceOf(alice), 150);
        assertEq(vault.sharesOf(alice), 0);
        assertEq(vault.totalAssets(), 100);
        assertEq(vault.totalShares(), 66);
    }

    // Depositar sin haber hecho approve
    function testDepositWithoutApprove() public {
        address carol = makeAddr("carol");
        token.mint(carol, 100); // tiene tokens, pero nunca hizo approve

        vm.prank(carol);
        vm.expectRevert("insufficient allowance");
        vault.deposit(100);
    }

    //Retirar más shares de las que tenés.
    function testWithdrawMoreThanBalance() public {
        // 1. Bob intenta retirar 200 shares
        vm.prank(bob);
        vm.expectRevert('insufficient shares');
        vault.withdraw(200);

        vm.prank(bob);
        vm.expectRevert('cannot deposit zero');
        vault.deposit(0);

    }

    function testInflationAttack() public {
        address attacker = makeAddr("attacker");
        address victim = makeAddr("victim");
        token.mint(attacker, 10001);
        token.mint(victim, 15000);

        vm.prank(attacker);
        token.approve(address(vault), 1);
        vm.prank(victim);
        token.approve(address(vault), 15000);

        // 1. El atacante entra primero con 1 unidad: 1 share
        vm.prank(attacker);
        vault.deposit(1);

        // 2. Dona 10000 directo al vault, sin pasar por deposit()
        vm.prank(attacker);
        token.transfer(address(vault), 10000);

        // 3. La víctima deposita 15000 con el precio de la share ya inflado
        vm.prank(victim);
        vault.deposit(15000);
        assertEq(vault.sharesOf(victim), 15000); // recibió 15000 shares, no perdió nada

        // 4. La víctima retira su única share
        vm.prank(victim);
        vault.withdraw(1);
        assertEq(token.balanceOf(victim), 15000); // recibió 15000, no perdió nada

        // 5. El atacante retira la suya
        vm.prank(attacker);
        vault.withdraw(1);
        assertEq(token.balanceOf(attacker), 1); // recibió 1, perdió 10000

        // 6. El atacante dona 10000 más, pero ya no tiene shares para retirar
        assertEq(token.balanceOf(address(vault)), 10000); // la donación quedó trabada
    }
}