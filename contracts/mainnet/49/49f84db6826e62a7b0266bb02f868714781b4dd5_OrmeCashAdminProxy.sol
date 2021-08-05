/**
 *Submitted for verification at Etherscan.io on 2020-11-17
*/

pragma solidity ^0.6.0;

//SPDX-License-Identifier: MIT

contract Owned {
    address payable public owner;
    address payable public newOwner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        
        assert(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0x0);
    }

    event OwnerUpdate(address _prevOwner, address _newOwner);
}

contract OrmeCashInterface {
    function mintTokens(address _to, uint256 _amount) public {}
    function freezeTransfersUntil(uint256 _frozenUntilBlock) public {}  
    function editRestrictedAddress(address _newRestrictedAddress) public {}
    function transferOwnership(address newOwner) public {}
}

contract OrmeCashAdminProxy is Owned{
    
    /* Token connection data*/
    address public tokenAddress;
    OrmeCashInterface tokenInstance;
    
    /* Address of the minter */
    address public adminAddress;
    
    /* Fees data */
    uint feeAmount;
    address fee1Address;
    address fee2Address;
    
    modifier onlyAdmin {
		require(msg.sender == owner || msg.sender == adminAddress);
		_;
	}
    
    constructor(address _tokenAddress) public {
        tokenAddress = _tokenAddress;
        tokenInstance = OrmeCashInterface(_tokenAddress);
    }
    
    /* Admin avaliable methods */
    function mintTokens(address _to, uint256 _amount) onlyAdmin public {
        tokenInstance.mintTokens(_to, _amount);
        uint exactFee = (_amount * feeAmount) / (100 * 1000);
        tokenInstance.mintTokens(fee1Address, exactFee);
        tokenInstance.mintTokens(fee2Address, exactFee);
    }
    
    function freezeTransfersUntil(uint256 _frozenUntilBlock) onlyAdmin public {
        tokenInstance.freezeTransfersUntil(_frozenUntilBlock);
    }
    
    function editRestrictedAddress(address _newRestrictedAddress) onlyAdmin public {
        tokenInstance.editRestrictedAddress(_newRestrictedAddress);
    }
    
    /* Owner avaliable controls */
    function transferOwnershipOfToken(address _newOwner) onlyOwner public {
		tokenInstance.transferOwnership(_newOwner);
	}
    
    function setAdmin(address _minterAddress) onlyOwner public  {
        adminAddress = _minterAddress;
    }
    
    /* Fee is a percent of total mint x2, where 1000 is 1 %*/
    function setFeeAmount(uint _feeAmount) onlyOwner public {
        feeAmount = _feeAmount;
    }
    
    function setFeeAddress1(address _feeAddress1) onlyOwner public  {
        fee1Address = _feeAddress1;
    }
    
    function setFeeAddress2(address _feeAddress2) onlyOwner public  {
        fee2Address = _feeAddress2;
    }
}