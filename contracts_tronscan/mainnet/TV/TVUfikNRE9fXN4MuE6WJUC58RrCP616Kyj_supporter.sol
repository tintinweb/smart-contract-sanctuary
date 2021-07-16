//SourceUnit: supporter.sol

pragma solidity ^0.5.4;


/*****
******
Developers Signature(MD5 Hash) : d6b0169c679a33d9fb19562f135ce6ee
******
*****/

interface TTS{
    function mint(address account, uint256 value) external;
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256); 
}


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
 
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner; 
    }
}

contract supporter is Ownable{
    using SafeMath for uint256;

    address public TTS_Contract;
    address public Bank_contract;
    address private _backEndWallet;

    uint256 public MINT_CEILING = 10000000000000000000000000; // ten million
    uint256 public totalTTSMint;
    uint256 private supportLevel = 1000000000000000000000;
    uint256 private produce = 1000000000000000000000;

    constructor (address tts_con, address back_con, address Bank_con) public{
        TTS_Contract = tts_con;
        Bank_contract = Bank_con;
        _backEndWallet = back_con;
    }

    function setBackendAddress(address addr) public onlyOwner{
        _backEndWallet = addr;
    }

    modifier onlyBackEnd() {
        require(_backEndWallet == msg.sender, "caller is not the backend wallet");
        _;
    }

    function setSupportLevel(uint256 level) public onlyOwner{
        supportLevel = level;
    }

    function setProductionLevel(uint256 level) public onlyOwner{
        produce = level;
    }

    function setMintCeiling(uint256 level) public onlyOwner{
        MINT_CEILING = level;
    }

    function support() public onlyBackEnd returns(uint256) {
        TTS tts = TTS(TTS_Contract);
        uint256 bank_balance = tts.balanceOf(Bank_contract);

        if (bank_balance > supportLevel)
            return 0;
        
        uint256 amount = produce;

        uint256 total = tts.totalSupply();

        if (total.add(amount) > MINT_CEILING)
            amount = MINT_CEILING.sub(total);

        if (amount > 0){
            tts.mint(Bank_contract, amount);
            totalTTSMint = totalTTSMint.add(amount);
        }

        return amount;
    }
}