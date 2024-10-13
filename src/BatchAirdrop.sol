// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

contract BatchAirdrop is ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public owner;

    uint256 public fee;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event FeeChanged(uint256 previousFee, uint256 newFee);
    event AirdropCoin(uint256 addressCount, uint256 totalAmount);
    event AirdropToken(uint256 addressCount, uint256 totalAmount);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "BatchAirdrop: not owner");
        _;
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;
        emit OwnershipTransferred(owner, _owner);
    }

    function setFee(uint256 _fee) public onlyOwner {
        fee = _fee;
        emit FeeChanged(fee, _fee);
    }

    function airdropCoin(
        address[] memory _to,
        uint256[] memory _amount
    ) public payable nonReentrant {
        require(_to.length == _amount.length, "BatchAirdrop: length not match");

        uint256 totalAmount = 0;

        for (uint256 i = 0; i < _amount.length; i++) {
            totalAmount += _amount[i];
        }

        require(
            msg.value == totalAmount + fee,
            "BatchAirdrop: msg.value not match with totalAmount + fee"
        );

        if (fee > 0) {
            (bool success, ) = owner.call{value: fee}("");
            require(success, "BatchAirdrop: transfer failed");
        }

        for (uint256 i = 0; i < _to.length; i++) {
            (bool success, ) = _to[i].call{value: _amount[i]}("");
            require(success, "BatchAirdrop: transfer failed");
        }

        emit AirdropCoin(_to.length, totalAmount);
    }

    function airdropToken(
        address _token,
        address[] memory _to,
        uint256[] memory _amount
    ) public payable nonReentrant {
        require(_to.length == _amount.length, "BatchAirdrop: length not match");

        require(msg.value >= fee, "BatchAirdrop: value not enough");
        if (fee > 0) {
            (bool success, ) = owner.call{value: fee}("");
            require(success, "BatchAirdrop: transfer failed");
        }

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < _amount.length; i++) {
            totalAmount += _amount[i];
        }

        SafeERC20.safeTransferFrom(
            IERC20(_token),
            msg.sender,
            address(this),
            totalAmount
        );

        for (uint256 i = 0; i < _to.length; i++) {
            SafeERC20.safeTransfer(IERC20(_token), _to[i], _amount[i]);
        }

        emit AirdropToken(_to.length, totalAmount);
    }
}
