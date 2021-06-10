/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

///
contract accreditation { 

    address public owner;
    bool lock = false;
    uint attr_number = 0;
    
    string public constant name = "TraceabilityToken";
    string public constant symbol = "TTC";
    uint public totalSupply = 100000;
    
    address public accredy_A;
    address public accredy_B;
    
    bool public fromAccredy_A;    
    bool public fromAccredy_B;
    
    struct Attribute {
        address onwer;
        string date;
        uint tracecode;
        string sheetid;
        string meta_1;
        string meta_2;
        string meta_3;
        bool exist;
    }
    
    //
    mapping(uint => Attribute) public attribute;
    
    //
    mapping(address => uint) balances;
    
    //
    mapping(address => mapping(address => uint256)) allowed;
    
    //
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    
    //
    event AddTransEvt( 
        string _evnType,
        uint _tracecode,
        string _sheetid
    );
    
    ///
    constructor ()  {
        owner = msg.sender;
        balances[msg.sender] = totalSupply;
    }
    
    ///
    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }
    
    ///
    function setAccredy_A (address  _accredy_A) public onlyOwner {
        accredy_A = _accredy_A;
    }
    
    ///
    function setAccredy_B (address _accredy_B)  public onlyOwner {
        accredy_B = _accredy_B;
    }
}