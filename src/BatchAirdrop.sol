// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

contract BatchAirdrop is ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public owner;

    uint256 public fee;

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "BatchAirdrop: not owner");
        _;
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;
    }   

    function setFee(uint256 _fee) public onlyOwner {
        fee = _fee;
    }

    function airdropCoin(
        address[] memory _to,
        uint256[] memory _amount
    ) public payable nonReentrant {
        require(
            _to.length == _amount.length,
            "BatchAirdrop: length not match"
        );

        uint256 totalAmount = 0;

        for (uint256 i = 0; i < _amount.length; i++) {
            totalAmount += _amount[i];
        }

        require(msg.value == totalAmount + fee, "BatchAirdrop: msg.value not match with totalAmount + fee");

        if (fee > 0) {
            payable(owner).transfer(fee);
        }

        for (uint256 i = 0; i < _to.length; i++) {
            (bool success, ) = _to[i].call{value: _amount[i]}("");
            require(success, "BatchAirdrop: transfer failed");
        }
    }

    function airdropToken(
        address _token,
        address[] memory _to,
        uint256[] memory _amount
    ) public payable nonReentrant {
        require(
            _to.length == _amount.length,
            "BatchAirdrop: length not match"
        );

        require(msg.value >= fee, "BatchAirdrop: value not enough");
        if (fee > 0) {
            payable(owner).transfer(fee);
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
    }
}

