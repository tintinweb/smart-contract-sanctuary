//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ERC20Token.sol';

contract Vevraj is ERC20Token {
    constructor(uint256 _initialSupply) ERC20Token("Vevraj", "VEV"){
        mint(_initialSupply);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ERC20i {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);

    event Transfer(address _from, address _to, uint256 _value);
    event Approval(address _owner, address _spender, uint256 _value);
}

abstract contract ERC20Token is ERC20i {

    struct Holders {
        uint256 eBalance;
        mapping(address => uint256) eAllowance;
    }

    address admin;
    string eName;
    string eSymbol;
    uint256 eTotalSupply;
    mapping(address => Holders) holder;

    constructor(string memory _name, string memory _symbol) {
        require(tx.origin == msg.sender, "origin and sender are different");
        admin = msg.sender;
        eName = _name;
        eSymbol = _symbol;
    }

    modifier onlyAdmin() {
        require(admin == msg.sender, "Only Admin of Token and Call This Function");
        _;
    }

    function mint(uint256 _value) onlyAdmin public {
        holder[admin].eBalance += _value * (10 ** decimals());
        eTotalSupply += _value;
        emit Transfer(address(0x0), admin, _value);
    }

    function isAllowed(address _from, uint256 _value) internal view returns (bool) {
        return holder[_from].eAllowance[msg.sender] >= _value;
    }

    function name() public override view returns (string memory) {
        return eName;
    }

    function symbol() public override view returns (string memory) {
        return eSymbol;
    }

    function decimals() public override pure returns (uint8) {
        return 18;
    }

    function totalSupply() public override view returns (uint256) {
        return eTotalSupply;
    }

    function balanceOf(address _owner) public override view returns (uint256) {
        return holder[_owner].eBalance;
    }

    function transfer(address _to, uint256 _value) public override returns (bool) {
        require(holder[msg.sender].eBalance >= _value, "Minimum Token Not Available");
        holder[msg.sender].eBalance -= _value;
        holder[_to].eBalance += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
        require(isAllowed(_from, _value), "Spender not Authorized or Out of Allowance");
        require(holder[_from].eBalance >= _value, "Minimum Token Not Available");
        holder[_from].eAllowance[msg.sender] -= _value;
        holder[_from].eBalance -= _value;
        holder[_to].eBalance += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public override returns (bool) {
        holder[msg.sender].eAllowance[_spender] = 0;
        holder[msg.sender].eAllowance[_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public override view returns (uint256) {
        return holder[_owner].eAllowance[_spender];
    }
}