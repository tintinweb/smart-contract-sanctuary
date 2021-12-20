/**
 *Submitted for verification at Etherscan.io on 2021-12-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract LememeToken is Ownable {
    string public name;
    string public symbol;
    uint8 public decimals;
    bool mintAllowed = true;
    uint256 public totalSupply;
    uint256 decimalfactor;
    uint256 public Max_Token;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    constructor(
        string memory SYMBOL,
        string memory NAME,
        uint8 DECIMALS
    ) {
        symbol = SYMBOL;
        name = NAME;
        decimals = DECIMALS;
        decimalfactor = 10**uint256(decimals);
        Max_Token = 307_000_000 * decimalfactor;

        mint(
            0x2C203C695aF8A8504DE07207E2395c6F6260D023,
            32_000_000 * decimalfactor
        ); //Team
        mint(
            0x48a0e698dC6b7bfDFbe522bC90717eEf3EDb7EfD,
            28_000_000 * decimalfactor
        ); //Pancake Swap
        mint(
            0x2C6b5E560DFd88231Abd59cBB6f1993B0181546f,
            25_000_000 * decimalfactor
        ); //Legend Drop
        mint(
            0x30Bad413013a32EFADC323349F3FaB97Da424648,
            24_000_000 * decimalfactor
        ); //Other Mainnets
        mint(
            0x32808206b1913373251461E2916ff2F204328019,
            50_000_000 * decimalfactor
        ); //Reserve for Future Listng
        mint(
            0x364874F08B07DF9DCc94c3A82cE318dab188294B,
            10_000_000 * decimalfactor
        ); //Vote
        mint(
            0x3C35BB702f8Ed9997655bAF64AE70E8ca670566D,
            30_000_000 * decimalfactor
        ); //Joining Community Rewards
        mint(
            0xD70453BaCFA41690dCa611565d7227836Bbe18f3,
            10_000_000 * decimalfactor
        ); //Legends Cryotic Wages Payment System
        mint(
            0x8278305dDe990A3C84B386d504fE00f1d119270A,
            9_000_000 * decimalfactor
        ); //Operations
        mint(
            0x95Ad43c89A743A931898500F3bdD2651531224Ca,
            7_000_000 * decimalfactor
        ); //NFT Development
        mint(
            0xF9e47B905bb1aA9560E5CdCb34A2ddFDcAbf46FA,
            7_000_000 * decimalfactor
        ); //Advisors
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        require(_to != address(0));
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        uint256 previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender], "Allowance error");
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        Max_Token -= _value;
        totalSupply -= _value;
        emit Burn(msg.sender, _value);
        return true;
    }

    function mint(address _to, uint256 _value) public returns (bool success) {
        require(Max_Token >= (totalSupply + _value));
        require(mintAllowed, "Max supply reached");
        if (Max_Token == (totalSupply + _value)) {
            mintAllowed = false;
        }
        require(msg.sender == owner, "Only Owner Can Mint");
        balanceOf[_to] += _value;
        totalSupply += _value;
        require(balanceOf[_to] >= _value);
        emit Transfer(address(0), _to, _value);
        return true;
    }
}