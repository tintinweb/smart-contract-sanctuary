/**
 *Submitted for verification at Etherscan.io on 2021-09-27
*/

//SPDX-License-Identifier: MIT

//DES Token Linear Vesting contract 2021.08
//Author: Henry Onyebuchi

pragma solidity 0.8.4;

interface IERC20 {
    function transfer(address to, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function approve(address spender, uint tokens) external returns (bool success);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function totalSupply() external view returns (uint);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

 contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(owner, _newOwner);
    }
}

contract TeamVest is Ownable {

    IERC20 private _DES;
    address public beneficiary;
    uint private _init;
    uint private _start;
    uint private _release;
    uint private _onTGERate;

    struct Beneficiary {
        bool whitelisted;
        uint total1;
        uint taken1;  
        uint total2;
        uint taken2; 
    }

    mapping(address => Beneficiary) private _beneficiaries;

    event Withdrawal(
        address indexed beneficiary, 
        uint amount
    );

    constructor(
        address desAddress,
        address _beneficiary,
        uint _total,
        uint onTGERate) Ownable() {
        
        _DES = IERC20(desAddress);
        _onTGERate = onTGERate;
        beneficiary = _beneficiary;
        _whitelist(_total);
    }

    function initialize(
        uint _startInSeconds,
        uint _releaseInSeconds)
        external onlyOwner() {

        require(
            _start == 0,
            "already initialized"
        );
        
        _start = block.timestamp + _startInSeconds;
        _release = block.timestamp +  _releaseInSeconds;
        _init = block.timestamp;
    }

    function _whitelist( 
        uint _total) 
        internal {   
            
        Beneficiary storage ben = 
        _beneficiaries[beneficiary];           

        uint total1 = (_total * _onTGERate) / 100;
        uint total2 = _total - total1;
        
        ben.total1 = total1;
        ben.total2 = total2;
    }

    function getReleaseTime()
        external view returns(
        uint initialRelease, 
        uint finalRelease) {
            
        uint start = _start;
        uint release = _release;
        
        block.timestamp > start 
        ? initialRelease = 0
        : initialRelease = start - block.timestamp;
        
        block.timestamp > release 
        ? finalRelease = 0
        : finalRelease = release - block.timestamp;
    }

    function getBalance() 
        external view returns(uint balance) {
        
        Beneficiary memory ben = 
        _beneficiaries[beneficiary];

        return (
            (ben.total1 + ben.total2) 
            - (ben.taken1 + ben.taken2)
        );
    }
     
    function getAvailable() 
        external view returns(uint token_released) {
        
        uint release1 = _released1();
        uint release2 = _released2();
        
        return (release1 + release2);
    } 

    function getStruct() 
        external view returns(Beneficiary memory userStruct) {

        return _beneficiaries[beneficiary];
    }

    function claim(
        ) external returns(bool success) {
        
        require(
            _start != 0,
            "not yet initialized"
        );
        
        uint release1 = _released1();
        uint release2= _released2();
        
        require(
            release1 > 0 || release2 > 0, 
            "You do not have any balance available"
        );
        
        if (release1 > 0) _claim1(release1);
        if (release2 > 0) _claim2(release2); 
        
        return true; 
    }

    function _claim1(
        uint released) 
        internal {
        
        _beneficiaries[beneficiary].taken1 += released;
        require(
            _DES.transfer(beneficiary, released), 
            "Error in sending token"
        );
        
        uint release = _start;

        if (release <= block.timestamp) {
            _beneficiaries[beneficiary].total1 = 0;
            _beneficiaries[beneficiary].taken1 = 0;
        }
        emit Withdrawal(beneficiary, released);
    }

    function _claim2(
        uint released)
        internal {
        
        _beneficiaries[beneficiary].taken2 += released;
        require(
            _DES.transfer(beneficiary, released), 
            "Error in sending token"
        );
        
        uint release = _release;

        if (release <= block.timestamp) {
            _beneficiaries[beneficiary].total2 = 0;
            _beneficiaries[beneficiary].taken2 = 0;
        }
        emit Withdrawal(beneficiary, released);
    }

    function _released1(
        ) internal view returns(uint) {

        uint start = _init;
        uint release = _start;
        uint total = _beneficiaries[beneficiary].total1;
        uint taken = _beneficiaries[beneficiary].taken1;
        uint releasedPct;
        
        if (block.timestamp <=  start) return 0;
        if (block.timestamp >= release) releasedPct = 100;
        else releasedPct = 
            ((block.timestamp - start) * 100000) 
            / ((release - start) * 1000);
        
        uint released = (total * releasedPct) / 100;
        return released - taken;
    }

    function _released2(
        ) internal view returns(uint) {

        uint start = _start;
        uint release = _release;
        uint total = _beneficiaries[beneficiary].total2;
        uint taken = _beneficiaries[beneficiary].taken2;
        uint releasedPct;
        
        if (block.timestamp <=  start) return 0;
        if (block.timestamp >= release) releasedPct = 100;
        else releasedPct = 
            ((block.timestamp - start) * 100000) 
            / ((release - start) * 1000);
        
        uint released = (total * releasedPct) / 100;
        return released - taken;
    }
}