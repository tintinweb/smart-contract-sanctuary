// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

// An ethereum smart contract to split funds between an array of addresses 
// according to their respective percentages.
import './splitContract.sol';

// An ethereum factory smart contract to produce more children contracts
// which would be used to split funds in a specific ratio.
contract contractFactory {
    
    // The array of contracts produced by this factory contract.
    address[] public contracts;

    // Event to trigger the creation of new Child contract address.
    event ChildContractCreated (address splitterContractAddress);
        
    // Returns the length of all the contracts deployed through 
    // this factory contract.
    function getContractCount() public view returns(uint) {
        return contracts.length;
    }
    
    /// @param _address The address array of the new contract in which the funds 
    /// will be splitted.
    /// @param _share The precentage array of the respective ethereum addresses
    /// provided for the funds to get splitted.
    function registerContract(address payable[] memory _address, uint[] memory _share) 
    public payable returns(address) {
        uint256 length = _share.length;
        uint256 totalPercentage = 0;
        uint256 maxPercentage = 100;
        for (uint256 i = 0; i < length; i++) {
            totalPercentage = totalPercentage + _share[i];
        }
        require(maxPercentage >= totalPercentage, "Total percentage should not be greater than 100");
        splitContract c = new splitContract( _address, _share);
        contracts.push(address(c));
        emit ChildContractCreated(address(c));
        return address(c);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

contract splitContract {

    // The struct of ethereum addresses and its respective share provided at the time 
    // of contract genertaion in which the funds will be spiltted.
    struct Payee{
        address payable payeeAddress;
        uint256 share;
    }

    Payee[] public payees;

    // Event to trigger the receiving of amount to one of the addresses from address array.

    event LogSplitted(uint value, Payee[] payees);
    event LogSplitterCreated(Payee[] payees, address indexed splitterAddress);
    
    // This is the constructor of the contract. It is called at deploy time.
    
    /// @param _payee The address array of the new contract in which the funds 
    /// will be splitted.
    /// @param _share The precentage array of the respective ethereum addresses
    /// provided for the funds to get splitted.
    constructor (address payable[] memory _payee, uint[] memory _share) {
        uint256 length = _payee.length;
        require(length == _share.length, "Mismatch between payees and share arrays");
        for (uint256 i = 0; i < length; i++) {
            Payee memory payee = Payee(_payee[i], _share[i]);
            payees.push(payee);
        }
        emit LogSplitterCreated(payees, address(this));
    }
    
    // This function will be run when a transaction is sent to the contract
    // without any data and send the funds in the percentage ratio as provided
    // at the time of creation of the contract.
    receive() external payable {
        require(msg.value > 0, "Fund value 0 is not allowed");
        uint256 amount = msg.value;
        for(uint256 i = 0; i < payees.length; i++){
            address payable participant = payees[i].payeeAddress;
            uint256 computedShare = (amount * payees[i].share) /100;
            participant.transfer(computedShare);
        }
        emit LogSplitted(amount, payees);
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "london",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}