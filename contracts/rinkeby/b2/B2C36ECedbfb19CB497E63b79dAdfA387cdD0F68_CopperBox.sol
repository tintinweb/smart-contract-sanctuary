/**
 *Submitted for verification at Etherscan.io on 2021-10-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface MultiSignature {
    function is_apporved(uint) external view returns (string memory, uint, address, bool);
}

contract CopperBox {
    string public constant name = "Copper Box";
    string public constant symbol = "copper";
    uint8 public constant decimals = 18;

    uint public totalSupply = 0;
    uint public totalSupplyOfSummoner = 0;
    uint public totalSupplyOfMonster = 0;

    mapping(address => uint) public totalSupplyOfOperator;
    mapping(address => uint) public totalSupplyOfOperatorOfSummoner;
    mapping(address => uint) public totalSupplyOfOperatorOfMonster;
    
    MultiSignature constant ms = MultiSignature(0x2eFCCBB594d6283864589b0dfD3c77A37A95E778);

    mapping(uint => uint) public balanceOfSummoner;
    mapping(uint => uint) public balanceOfMonster;

    mapping(address => bool) public isApproved;
    
    event Transfer(string subject, uint indexed from, uint indexed to, uint amount);
    event Whitelist(string symbol, uint index, address operator, bool arg);

    modifier is_approved() {
        require(isApproved[msg.sender], "Not approved");
        _;
    }

    function mint_to_summoner(uint _summnoer, uint _amount) external is_approved{
        totalSupply += _amount;
        totalSupplyOfSummoner += _amount;
        totalSupplyOfOperator[msg.sender] += _amount;
        totalSupplyOfOperatorOfSummoner[msg.sender] += _amount;

        balanceOfSummoner[_summnoer] += _amount;

        emit Transfer("Summoner", _summnoer, _summnoer, _amount);
    }

    function mint_to_monster(uint _monster, uint _amount) external is_approved{
        totalSupply += _amount;
        totalSupplyOfMonster += _amount;
        totalSupplyOfOperator[msg.sender] += _amount;
        totalSupplyOfOperatorOfMonster[msg.sender] += _amount;

        balanceOfMonster[_monster] += _amount;

        emit Transfer("Monster", _monster, _monster, _amount);
    }

    function transfer_to_summoner(uint _from, uint _to, uint _amount) external is_approved{
        balanceOfSummoner[_from] -= _amount;
        balanceOfSummoner[_to] += _amount;

        emit Transfer("Summoner", _from, _to, _amount);
    }

    function transfer_to_monster(uint _from, uint _to, uint _amount) external is_approved{
        balanceOfMonster[_from] -= _amount;
        balanceOfMonster[_to] += _amount;

        emit Transfer("Monster", _from, _to, _amount);
    }

    function whitelist(uint _index) external {
        string memory _symbol;
        uint approved = 0;
        address operator = address(0);
        bool arg = false;
        
        (_symbol, approved, operator, arg) = ms.is_apporved(_index);
        
        require(keccak256(abi.encodePacked(_symbol)) == keccak256(abi.encodePacked(symbol)));
        require(approved >= 2, "Less than 2");

        isApproved[operator] = arg;

        emit Whitelist(_symbol, _index, operator, arg);
    }

}