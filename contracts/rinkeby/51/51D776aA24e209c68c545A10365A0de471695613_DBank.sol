/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

contract DBank {
    address public manager;
    mapping(address => uint256) private balances;
    mapping(address => mapping(uint256 => bool)) nonce;

    constructor() {
        manager = msg.sender;
    }

    event EtherDeposited(address account, uint256 amount);
    event EtherWithdrawn(address account, uint256 amount);
    event Transaction(address payer, address reciver, uint256 amount);

    function checkBankCapital() public view managerOnly returns (uint256) {
        return address(this).balance;
    }

    function checkBalance(address _address) public view returns (uint256) {
        return balances[_address];
    }

    function depositBalance() public payable {
        uint256 amount = uint256(msg.value);
        balances[msg.sender] += amount;
        emit EtherDeposited(msg.sender, amount);
    }

    function withdrawBalance(uint256 _amount) public {
        address account = msg.sender;
        require(_amount <= balances[account], "You don't have enough ether!");
        balances[account] -= _amount;
        payable(account).transfer(_amount);
    }

    function transferBalance(
        address _payer,
        uint256 _amount,
        uint256 _nonce,
        bytes memory _signature
    ) public {
        address sender = msg.sender;
        require(!nonce[sender][_nonce], "Transaction is already performed!");
        nonce[sender][_nonce] = true;

        bytes32 hash =
            prefixed(
                keccak256(abi.encodePacked(_payer, sender, _amount, _nonce))
            );

        require(
            recoverAddress(hash, _signature) == _payer,
            "Transaction is not valid"
        );

        require(balances[_payer] >= _amount);

        balances[_payer] -= _amount;

        payable(sender).transfer(_amount);
        emit Transaction(_payer, sender, _amount);
    }

    function recoverAddress(bytes32 _hash, bytes memory _signature)
        internal
        pure
        returns (address)
    {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(_signature);

        return ecrecover(_hash, v, r, s);
    }

    function splitSignature(bytes memory _signature)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        require(_signature.length == 65);

        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
        if (v == 0 || v == 1) {
            v += 27;
        }

        require(v == 27 || v == 28, "Invalid Signature");
        return (v, r, s);
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    modifier managerOnly() {
        require(msg.sender == manager, "Unauthorized access!");
        _;
    }
}