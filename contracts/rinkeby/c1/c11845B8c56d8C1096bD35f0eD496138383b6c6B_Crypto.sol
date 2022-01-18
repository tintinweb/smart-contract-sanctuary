/**
 *Submitted for verification at Etherscan.io on 2017-07-19
*/

pragma solidity 0.8.7;
contract Crypto {

    string public imageHash = "";

    address owner;

    string public standard = 'Crypto';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    uint public nextPunkIndexToAssign = 0;

    bool public allPunksAssigned = false;
    uint public punksRemainingToAssign = 0;

    mapping (uint => address) public punkIndexToAddress;

    mapping (address => uint256) public balanceOf;

    struct Offer {
        bool isForSale;
        uint punkIndex;
        address seller;
        uint minValue;
        address onlySellTo;
    }

    mapping (uint => Offer) public punksOfferedForSale;

    event Assign(address indexed to, uint256 punkIndex);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event PunkTransfer(address indexed from, address indexed to, uint256 punkIndex);
    event PunkNoLongerForSale(uint indexed punkIndex);

    constructor() payable {
        owner = msg.sender;
        totalSupply = 10000;
        punksRemainingToAssign = totalSupply;
        name = "CRYPTO";
        symbol = "C";
        decimals = 0;
    }

    function setInitialOwner(address to, uint punkIndex) public {
        require(msg.sender == owner);
        require(!allPunksAssigned);
        require(punkIndex < 10000);
        if (punkIndexToAddress[punkIndex] != to) {
            if (punkIndexToAddress[punkIndex] != address(0)) {
                balanceOf[punkIndexToAddress[punkIndex]]--;
            } else {
                punksRemainingToAssign--;
            }
            punkIndexToAddress[punkIndex] = to;
            balanceOf[to]++;
            emit Assign(to, punkIndex);
        }
    }

    function allInitialOwnersAssigned() public {
        require(msg.sender == owner);
        allPunksAssigned = true;
    }

    function transferPunk(address to, uint punkIndex) external {
        require(allPunksAssigned);
        require(punkIndexToAddress[punkIndex] == msg.sender);
        require(punkIndex < 10000);
        if (punksOfferedForSale[punkIndex].isForSale) {
            punkNoLongerForSale(punkIndex);
        }
        punkIndexToAddress[punkIndex] = to;
        balanceOf[msg.sender]--;
        balanceOf[to]++;
        emit Transfer(msg.sender, to, 1);
        emit PunkTransfer(msg.sender, to, punkIndex);
    }

    function punkNoLongerForSale(uint punkIndex) public {
        require(allPunksAssigned);
        require(punkIndexToAddress[punkIndex] == msg.sender);
        require(punkIndex < 10000);
        punksOfferedForSale[punkIndex] = Offer(false, punkIndex, msg.sender, 0, address(0));
        emit PunkNoLongerForSale(punkIndex);
    }
}