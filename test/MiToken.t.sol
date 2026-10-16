// SPDX-License-Identifier: MIT
pragma solidity ^0.8.36;

import {Test} from "forge-std/Test.sol";
import {MiToken} from "../src/MiToken.sol";

contract MiTokenTest is Test {
    MiToken token;
    address alice;
    address bob;

    function setUp() public {
        token = new MiToken();
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        // Le damos balance a alice manualmente para poder testear transfer
        // (vamos a ver esto del "mint" en la próxima función que escribamos)
    }

    function testTransferRevierteSinBalance() public {
        vm.prank(alice); // simula que la próxima llamada la hace alice
        vm.expectRevert("insufficient balance");
        token.transfer(bob, 100);
    }

    function testFlowTransfer() public {
        // Le damos balance a alice
        vm.prank(token.owner());
        token.mint(alice, 1000);

        vm.prank(alice);
        token.approve(bob, 200);

        vm.prank(bob);
        token.transferFrom(alice, bob, 150);

        // Verificamos balances
        assertEq(token.balanceOf(alice), 850);
        assertEq(token.balanceOf(bob), 150);
        assertEq(token.allowance(alice, bob), 50);
    }

    function testTransferFromNotAllowed() public {
        // Le damos balance a alice
        vm.prank(token.owner());
        token.mint(alice, 1000);

        vm.prank(bob);
        vm.expectRevert("insufficient allowance");
        token.transferFrom(alice, bob, 150);
    }
}