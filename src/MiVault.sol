// SPDX-License-Identifier: MIT
pragma solidity ^0.8.36;

import {IERC20} from "./IERC20.sol";

contract MiVault {
    IERC20 public asset;
    address public owner = msg.sender;

    string public name = "Vault Shares";
    string public symbol = "vMTK";
    uint256 public totalShares;
    uint256 private _totalAssets;
    mapping(address => uint256) public sharesOf;

    event Deposit(address indexed user, uint256 assets, uint256 shares);
    event Withdraw(address indexed user, uint256 assets, uint256 shares);

    constructor(address _assetAddress) {
        asset = IERC20(_assetAddress);
    }

    function totalAssets() public view returns (uint256) {
        return _totalAssets;
    }

    function deposit(uint256 amount) public returns (uint256 shares) {
        require(amount > 0, "cannot deposit zero");

        if (totalShares == 0) {
            shares = amount;
        } else {
            shares = (amount * totalShares) / _totalAssets;
        }

        require(shares > 0, "zero shares minted");

        totalShares += shares;
        sharesOf[msg.sender] += shares;
        _totalAssets += amount;

        require(asset.transferFrom(msg.sender, address(this), amount), "transfer failed");

        emit Deposit(msg.sender, amount, shares);
    }

    function withdraw(uint256 shares) public returns (uint256 assets) {
        require(shares > 0, "cannot withdraw zero");
        require(sharesOf[msg.sender] >= shares, "insufficient shares");

        assets = (shares * _totalAssets) / totalShares;

        require(assets > 0, "zero assets withdrawn");

        totalShares -= shares;
        sharesOf[msg.sender] -= shares;
        _totalAssets -= assets;

        require(asset.transfer(msg.sender, assets), "transfer failed");

        emit Withdraw(msg.sender, assets, shares);
    }

    function harvest() public {
        require(msg.sender == owner, "only owner");
        uint256 balance = asset.balanceOf(address(this));
        require(balance > _totalAssets, "nothing to harvest");
        _totalAssets = balance;
    }
}