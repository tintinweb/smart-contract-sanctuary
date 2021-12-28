/**
 *Submitted for verification at FtmScan.com on 2021-12-28
*/

// File: @cryptoshuraba/assetbox/contracts/Whitelist.sol


pragma solidity ^0.8.7;


interface IMultiSignature {
    function is_apporved(uint) external view returns (string memory, uint, address, bool);
}

contract Whitelist {

    mapping(uint => bool) public hasBeenProcessed;

    mapping(address => bool) public isApproved;

    address public immutable ms;
    string private _symbol;

    modifier is_approved() {
        require(isApproved[msg.sender], "Not approved");
        _;
    }

    event Whitelisted(string symbol, uint index, address operator, bool arg);

    constructor(address ms_, string memory symbol_) {
       ms = ms_;
       _symbol = symbol_;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function whitelist(uint proposalIndex) external {
        string memory returnedSymbol;
        uint approved = 0;
        address operator = address(0);
        bool arg = false;
        
        (returnedSymbol, approved, operator, arg) = IMultiSignature(ms).is_apporved(proposalIndex);
        
        require(!hasBeenProcessed[proposalIndex], "Proposal has been processed");
        require(keccak256(abi.encodePacked(returnedSymbol)) == keccak256(abi.encodePacked(symbol())));
        require(approved >= 2, "Less than 2");

        isApproved[operator] = arg;
        hasBeenProcessed[proposalIndex] = true;

        emit Whitelisted(symbol(), proposalIndex, operator, arg);
    }
}
// File: 2.0/AssetBox.sol


pragma solidity ^0.8.7;


interface IAssetBox {
    function totalSupply() external view returns (uint);
    function getTotalSupplyOfRole(uint8 roleIndex) external view returns (uint);
    function getbalance(uint8 roleIndex, uint tokenID) external view returns (uint);
    function mint(uint8 roleIndex, uint tokenID, uint amount) external;
    function setRole(uint8 index, address role) external;
    function getRole(uint8 index) external view returns (address);
    function transfer(uint8 roleIndex, uint from, uint to, uint amount) external;
    function burn(uint8 roleIndex, uint tokenID, uint amount) external;
}


contract AssetBox is Whitelist, IAssetBox {

    string public name;
    uint8 public constant decimals = 0;

    mapping(uint8 => address) private roles;

    uint public override totalSupply;

    mapping(uint8 => uint) private totalSupplyOfRole;

    mapping(uint8 => mapping(uint => uint)) private balance;

    event Mint(uint8 roleIndex, uint indexed from, uint amount);
    event Transfer(uint8 roleIndex, uint indexed from, uint indexed to, uint amount);
    event Burn(uint8 roleIndex, uint indexed from, uint amount);

    constructor (address ms_, string memory symbol_, string memory name_) Whitelist(ms_, symbol_) {
        name = name_;
    }

    function getTotalSupplyOfRole(uint8 roleIndex) external view override returns (uint){
        return totalSupplyOfRole[roleIndex];
    }

    function getbalance(uint8 roleIndex, uint tokenID) external view override returns (uint){
        return balance[roleIndex][tokenID];
    }

    function mint(uint8 roleIndex, uint tokenID, uint amount) external override is_approved {
        totalSupply += amount;
        totalSupplyOfRole[roleIndex] += amount;
        balance[roleIndex][tokenID] += amount;

        emit Mint(roleIndex, tokenID, amount);
    }

    function getRole(uint8 index) external view override returns (address) {
        return roles[index];
    }

    function setRole(uint8 index, address role) external override is_approved{
        roles[index] = role;
    }

    function transfer(uint8 roleIndex, uint from, uint to, uint amount) external override is_approved{
        require(balance[roleIndex][from] >= amount, "transfer amount exceeds balance");

        balance[roleIndex][from] -= amount;
        balance[roleIndex][to] += amount;

        emit Transfer(roleIndex, from, to, amount);
    }

    function burn(uint8 roleIndex, uint tokenID, uint amount) external override is_approved {
        require(balance[roleIndex][tokenID] >= amount, "burn amount exceeds balance");

        totalSupply -= amount;
        totalSupplyOfRole[roleIndex] -= amount;
        balance[roleIndex][tokenID] -= amount;

        emit Burn(roleIndex, tokenID, amount);
    }

}