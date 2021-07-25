/**
 *Submitted for verification at Etherscan.io on 2021-07-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.17;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b; assert(a == 0 || c / a == b); return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b; return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a); return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b; assert(c >= a); return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0); return a % b;
    }
}

contract Ownable {
    address payable public owner;
    address payable public newOwner;
    modifier onlyOwner {require(msg.sender == owner);_;}
    function transferOwnership(address payable _newOwner) public onlyOwner {newOwner = _newOwner;}
    function acceptOwnership() public {require(msg.sender == newOwner); owner = newOwner;}
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed account, address indexed spender, uint256 value);
}

contract ERC20Detailed is IERC20 {
    string public _name;
    string public _symbol;
    uint8 public _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }
    
    function name() public view returns (string memory) {
        return _name;
    }
    
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

contract ERC20 is IERC20 {}
contract TimeLocked {
    address internal vault;
    uint256 internal unlockDate;
    uint256 internal timelockStart;
}

contract ERAProtocol {

    uint256 public mintingStartTime;
    uint256 internal coinAgeBaseRate;
    
    uint256 internal minimumAge;
    uint256 internal maximumAge;
    
    uint256 internal timeInterval;
    uint256 internal timeBaseRate;

    function proofOfAgeMinting() internal returns (bool);
    function proofOfTimeMinting() internal returns (bool);
    function transactionReward(address account) internal returns (bool);
    
    function coinAge() internal view returns (uint);
    function annualCoinAgeRate() internal view returns (uint256);

    event ProofOfAgeMinting(address indexed account, uint256 _tokenAgeRewards);
    event ProofOfTimeMinting(address indexed account, uint256 _timeRewards);
    
    event BlockTransaction(address indexed account, uint256 _blockTransaction);
    event BlockNumberTransaction(address indexed account, uint256 _blockNumber);
}

//--------------------------------------------------------------------------------------
//Constructor
//--------------------------------------------------------------------------------------

contract EraCoin is ERC20, ERC20Detailed,
    ERAProtocol, TimeLocked, Ownable {
        
    using SafeMath for uint256;

    uint256 public totalSupply;
    uint256 public maxTotalSupply;
    uint256 internal circulatingSupply;
    
    uint256 internal genesisBlockNumber;
    uint256 internal genesisStartTime;
    uint256 internal lastBlockTime;
    
    address internal tokenContract = address(this);

    //Set owner address
    
    address internal contractOwner = 0xF992e3BCAC466161DcE2E1b4fBAaCa6d4e129313;
    
    //Set vault wallet address
    //to locked team and developer token allocations also LP's tokens
    //Vault wallet locked automatically until specified time
    
    address internal vaultWallet = 0x184065a90257D3C56B0073Fe813845046c07eAB4;

    //Set unlock date for vault wallet in unix timestamp
    uint256 internal unlockDate = 1785024000; //Sun Jul 26 2026 00:00:00 GMT+0000
    uint256 internal timelockStart;
    
    struct transferInStruct{uint128 amount; uint64 time;}

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowances;
    
    mapping(address => uint256) private lastMintedBlockTime;
    mapping(address => uint256) private lastClaimedTime;
    mapping(address => uint256) private lastTransactionBlockNumber;
    
    mapping(address => uint256) private lastWithdrawDividend;
    mapping(address => uint256) private lastBurnDividend;
    
    mapping(address => transferInStruct[]) transferIns;
    
    constructor() public ERC20Detailed("EraCoin", "0xERA", 18){
        owner = msg.sender;
        maxTotalSupply = 21000000 * (10**18);
        circulatingSupply = 109200 * (10**18);
        genesisStartTime = now;
        genesisBlockNumber = block.number;
        balances[msg.sender] = circulatingSupply;
        totalSupply = circulatingSupply;
        timelockStart = now;
    }

//--------------------------------------------------------------------------------------
//ERC20 function
//--------------------------------------------------------------------------------------
    
    function transfer(address to, uint256 value) external returns (bool) {
        require(balances[msg.sender] > 0, "Token holder cannot transfer if balances is 0");
        
        //--------------------------------------------------------------
        //Function to trigger internal
        //Proof-of-Age minting protocol, also
        //Block Transaction at the same time
        //--------------------------------------------------------------
        //Send transaction with 0 amount of token
        //to same address that stored token
        //--------------------------------------------------------------
        //Best option wallet is Metamask
        //--------------------------------------------------------------
        
        if(msg.sender == to && balances[msg.sender] > 0) return proofOfAgeMinting();
        if(msg.sender == to && balances[msg.sender] > 0) return transactionReward(msg.sender);
        
        //--------------------------------------------------------------
        //Function to trigger internal
        //Proof-of-Time minting protocol, also
        //and Block Transaction at the same time
        //--------------------------------------------------------------
        //Send transaction with 0 amount of token
        //to token contract address
        //--------------------------------------------------------------
        //Best option wallet is Metamask.
        //--------------------------------------------------------------
        
        if(tokenContract == to && balances[msg.sender] > 0) return proofOfTimeMinting();
        if(tokenContract == to && balances[msg.sender] > 0) return transactionReward(msg.sender);
        
        //Excluded account to trigger internal Proof-of-Age minting protocol layer
        
        if(msg.sender == to && contractOwner == msg.sender) revert();
        if(msg.sender == to && vaultWallet == msg.sender) revert();
        if(msg.sender == to && excluded[msg.sender] == true) revert();
        
        //Locked wallet cannot conducting transfers after specified time
        
        if(vaultWallet == msg.sender && now < unlockDate) revert();
        if(vaultWallet == msg.sender && now >= unlockDate) unlockDate = 0;
        
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        
        //Automatically trigger Block Transaction Rewards
        //when conducting transfer tokens or when receiving tokens
        
        transactionReward(msg.sender);
        transactionReward(to);
        
        //Function to reset time count of Proof-of-Time for token receiver
        
        lastClaimedTime[to] = now;
        
        //Function to reset token age to zero

        if(transferIns[msg.sender].length > 0) delete transferIns[msg.sender];
        uint64 _now = uint64(now);
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),_now));
        transferIns[to].push(transferInStruct(uint128(value),_now));
        
        emit Transfer(msg.sender, to, value);

        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 value) external returns (bool) {
        require(balances[sender] > 0, "Token holder cannot transfer if balances is 0");
        require(balances[sender] >= value, "Token holder does not have enough balance");
        require(allowances[sender][msg.sender] >= value, "Token holder does not have enough balance");
        
        //Locked wallet cannot make transfers after specified time
        
        if(vaultWallet == sender && now < unlockDate) revert();
        if(vaultWallet == sender && now >= unlockDate) unlockDate = 0;
        
        uint256 allowance = allowances[sender][msg.sender];
        allowances[sender][msg.sender] = allowance.sub(value);
        
        balances[sender] = balances[sender].sub(value);
        balances[recipient] = balances[recipient].add(value);
        
        //Automatically trigger Block Transaction Rewards
        //when conducting transfer tokens or when receiving tokens
        
        transactionReward(sender);
        transactionReward(recipient);
        
        //Function to reset token age to zero for tokens receiver
        
        lastClaimedTime[recipient] = now;
        
        if(transferIns[sender].length > 0) delete transferIns[sender];
        uint64 _now = uint64(now);
        transferIns[sender].push(transferInStruct(uint128(balances[sender]),_now));
        transferIns[recipient].push(transferInStruct(uint128(value),_now));
        
        emit Transfer(sender, recipient, value);
        
        return true;
    }
    
    function balanceOf(address account) external view returns (uint256 balance) {
        return balances[account];
    }

    function approve(address spender, uint256 value) external returns (bool) {
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address account, address spender) external view returns (uint256) {
        return allowances[account][spender];
    }
    
    function burn(address account, uint256 value) public onlyOwner {
        require(account != address(0));
        balances[msg.sender] = balances[msg.sender].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(account, address(0), value);
    }

    function mint(address account, uint256 value) public onlyOwner {
        require(account != address(0));
        require(totalSupply <= maxTotalSupply);
        if(totalSupply == maxTotalSupply) revert();
        balances[msg.sender] = balances[msg.sender].add(value);
        totalSupply = totalSupply.add(value);
        emit Transfer(address(0), msg.sender, value);
    }
    
    function destroySmartContract(address payable account) public onlyOwner {
        require(msg.sender == owner, "You are not the owner");
        selfdestruct(account);
    }

//--------------------------------------------------------------------------------------
//Internal Proof-of-Age minting protocol
//--------------------------------------------------------------------------------------

    uint256 public mintingStartTime; //Minting start time
    uint256 internal coinAgeBaseRate = 10**17; //Token age base rate minting
    uint256 internal minimumAge = 1 days; //Minimum Age for minting : 1 day
    uint256 internal maximumAge = 90 days; //Age of full weight : 90 days
    
    function claimProofOfAgeMinting() external returns (bool) {
        require(balances[msg.sender] > 0, "Cannot claim if balances is 0");
        proofOfAgeMinting();
    }
    
    function proofOfAgeMinting() internal returns (bool) {
        require(totalSupply <= maxTotalSupply);
        if(balances[msg.sender] <= 0) revert();
        if(transferIns[msg.sender].length <= 0) return false;
        
        //Excluded addresses from triggering 
        //internal Proof-of-Age minting protocol layer

        if(contractOwner == msg.sender) revert();
        if(vaultWallet == msg.sender) revert();
        if(excluded[msg.sender] == true) revert();
        
        uint256 tokenAgeRewards = getProofOfAgeRewards(msg.sender);
        totalSupply = totalSupply.add(tokenAgeRewards);
        balances[msg.sender] = balances[msg.sender].add(tokenAgeRewards);
        
        //Function to reset token age to zero after receiving minting token
        //and token holders must hold for certain period of time again
        //before triggering internal Proof-of-Age minting protocol layer
        
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));
        
        //Automatically triggering Block Transaction Rewards
        //when triggering internal Proof-of-Age minting protocol layer
        
        transactionReward(msg.sender);
        
        emit Transfer(address(0), msg.sender, tokenAgeRewards);
        emit ProofOfAgeMinting(msg.sender, tokenAgeRewards);
        
        return true;
    }

    function annualCoinAgeRate() internal view returns (uint coinAgeRate) {
        coinAgeRate = coinAgeBaseRate;

        //When total supply is less than 656,250
        //Coin Age rate is 100%

        if(totalSupply < 656250 * (10**18)) {
            coinAgeRate = (1000 * coinAgeBaseRate).div(100);

        //When total supply is over than 656,250 and less than 1,312,500
        //Coin Age rate is 50%

        } else if(totalSupply >= 656250 * (10**18) && totalSupply < 1312500 * (10**18)) {
            coinAgeRate = (500 * coinAgeBaseRate).div(100);

        //When total supply is over than 1,312,500 and less than 2,625,000
        //Coin Age rate is 25%

        } else if(totalSupply >= 1312500 * (10**18) && totalSupply < 2625000 * (10**18)) {
            coinAgeRate = (250 * coinAgeBaseRate).div(100);

        //When total supply is over than 2,625,000 and less than 5,250,000
        //Coin Age rate is 12.5%

        } else if(totalSupply >= 2625000 * (10**18) && totalSupply < 5250000 * (10**18)) {
            coinAgeRate = (125 * coinAgeBaseRate).div(100);

        //When total supply is over than 5,250,000 and less than 10,500,000
        //Coin Age rate is 6.25%

        } else if(totalSupply >= 5250000 * (10**18) && totalSupply < 10500000 * (10**18)) {
            coinAgeRate = ((125 * coinAgeBaseRate).div(2)).div(100);

        //When total supply is over than 10,500,000
        //Coin Age rate is 3.125%

        } else if(totalSupply >= 10500000 * (10**18)) {
            coinAgeRate = ((125 * coinAgeBaseRate).div(4)).div(100);
        }
    }

    function getProofOfAgeRewards(address account) internal view returns (uint) {
        require((now >= mintingStartTime) && (mintingStartTime > 0));
        require(mintingPaused == false);
        if(mintingPaused == true) return 0;
        
        if(totalSupply == maxTotalSupply) return 0;
        
        uint _now = now;
        uint _coinAge = getCoinAge(account, _now);
        if(_coinAge <= 0) return 0;
        uint coinAgeRate = coinAgeBaseRate;

        //When total supply is less than 656,250
        //Coin Age rate is 100%

        if(totalSupply < 656250 * (10**18)) {
            coinAgeRate = (1000 * coinAgeBaseRate).div(100);

        //When total supply is over than 656,250 and less than 1,312,500
        //Coin Age rate is 50%

        } else if(totalSupply >= 656250 * (10**18) && totalSupply < 1312500 * (10**18)) {
            coinAgeRate = (500 * coinAgeBaseRate).div(100);

        //When total supply is over than 1,312,500 and less than 2,625,000
        //Coin Age rate is 25%

        } else if(totalSupply >= 1312500 * (10**18) && totalSupply < 2625000 * (10**18)) {
            coinAgeRate = (250 * coinAgeBaseRate).div(100);

        //When total supply is over than 2,625,000 and less than 5,250,000
        //Coin Age rate is 12.5%

        } else if(totalSupply >= 2625000 * (10**18) && totalSupply < 5250000 * (10**18)) {
            coinAgeRate = (125 * coinAgeBaseRate).div(100);

        //When total supply is over than 5,250,000 and less than 10,500,000
        //Coin Age rate is 6.25%

        } else if(totalSupply >= 5250000 * (10**18) && totalSupply < 10500000 * (10**18)) {
            coinAgeRate = ((125 * coinAgeBaseRate).div(2)).div(100);

        //When total supply is over than 10,500,000
        //Coin Age rate is 3.125%

        } else if(totalSupply >= 10500000 * (10**18)) {
            coinAgeRate = ((125 * coinAgeBaseRate).div(4)).div(100);
        }

        return (_coinAge * coinAgeRate).div(365 * (10**18));
    }
    
    function coinAge() internal view returns (uint myCoinAge) {
        myCoinAge = getCoinAge(msg.sender, now);
    }

    function getCoinAge(address account, uint _now) internal view returns (uint _coinAge) {
        if(transferIns[account].length <= 0) return 0;
        for (uint i = 0; i < transferIns[account].length; i++){
            if(_now < uint(transferIns[account][i].time).add(minimumAge)) continue;
            uint coinAgeSeconds = _now.sub(uint(transferIns[account][i].time));
            if(coinAgeSeconds > maximumAge) coinAgeSeconds = maximumAge;
            _coinAge = _coinAge.add(uint(transferIns[account][i].amount) * coinAgeSeconds.div(1 days));
        }
    }
    
    function infoTokenAgeMinting(address account) external view returns (address, uint256, uint256, uint256) {
        uint _now = now;
        uint _coinAge = getCoinAge(account, _now);
        return (account, _coinAge, minimumAge, maximumAge);
    }

//--------------------------------------------------------------------------------------
//Internal Proof-of-Time minting protocol
//--------------------------------------------------------------------------------------

    uint256 internal timeInterval = 31556926; //1 years unix timestamp = 31556926 seconds
    uint256 internal timeBaseRate = 10000; //Default time minting rate is 100%
    
    function claimProofOfTimeMinting() external returns (bool) {
        require(balances[msg.sender] > 0, "Cannot claim if balances is 0");
        proofOfTimeMinting();
    }
    
    function proofOfTimeMinting() internal returns (bool) {
        require(totalSupply <= maxTotalSupply);
        if(balances[msg.sender] <= 0) return false;
        
        uint256 timeRewards = getProofOfTimeRewards(msg.sender);
        totalSupply = totalSupply.add(timeRewards);
        balances[msg.sender] = balances[msg.sender].add(timeRewards);

        //Function to reset token age of Proof-of-Age to zero
        
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));
        
        //Function to reset time count of Proof-of-Time to zero
        
        lastClaimedTime[msg.sender] = now;
        
        //Automatically triggering Block Transaction Rewards
        //when triggering internal Proof-of-Time minting protocol layer
        
        transactionReward(msg.sender);
        
        emit Transfer(address(0), msg.sender, timeRewards);
        emit ProofOfTimeMinting(msg.sender, timeRewards);
        
        return true;
    }

    function getProofOfTimeRewards(address account) internal returns (uint256) {
        require((now >= mintingStartTime) && (mintingStartTime > 0));
        require(mintingPaused == false);
        if(mintingPaused == true) return 0;
        
        if(totalSupply == maxTotalSupply) return 0;
        
        if(contractOwner == msg.sender) return 0;
        if(vaultWallet == msg.sender) return 0;
        if(excluded[msg.sender] == true) return 0;
        
        uint256 timeCount = now.sub(lastClaimedTime[msg.sender]);
        uint256 timeMintingRate = timeBaseRate;
        lastBlockTime = lastMintedBlockTime[msg.sender];
        
        //When total supply is less than 656,250
        //Time minting rate is 100%

        if(totalSupply < 656250 * (10**18)) {
            timeMintingRate = timeBaseRate.mul(1);

        //When total supply is over than 656,250 and less than 1,312,500
        //Time minting rate is 50%

        } else if(totalSupply >= 656250 * (10**18) && totalSupply < 1312500 * (10**18)) {
            timeMintingRate = timeBaseRate.div(2);

        //When total supply is over than 1,312,500 and less than 2,625,000
        //Time minting rate is 25%

        } else if(totalSupply >= 1312500 * (10**18) && totalSupply < 2625000 * (10**18)) {
            timeMintingRate = timeBaseRate.div(4);

        //When total supply is over than 2,625,000 and less than 5,250,000
        //Time minting rate is 12.5%

        } else if(totalSupply >= 2625000 * (10**18) && totalSupply < 5250000 * (10**18)) {
            timeMintingRate = timeBaseRate.div(8);

        //When total supply is over than 5,250,000 and less than 10,500,000
        //Time minting rate is 6.25%

        } else if(totalSupply >= 5250000 * (10**18) && totalSupply < 10500000 * (10**18)) {
            timeMintingRate = timeBaseRate.div(16);

        //When total supply is over than 10,500,000
        //Time minting rate is 3.125%

        } else if(totalSupply >= 10500000 * (10**18)) {
            timeMintingRate = timeBaseRate.div(32);
        }
        
        return balances[account].mul(timeMintingRate).mul(timeCount).div(timeInterval).div(1e4);
    }
    
    function infoTimeMinting(address account) external view returns (address, uint256, uint256) {
        uint256 timeCount = now.sub(lastClaimedTime[account]);
        return(account, timeCount, timeInterval);
    }

//--------------------------------------------------------------------------------------
//Set function for Proof-of-Time minting protocol
//--------------------------------------------------------------------------------------
    
    event ChangeTimeBaseRate(uint256 value);
    
    function setTimeInterval(uint256 _timeInterval) external onlyOwner {
        require(now >= unlockDate);
        timeInterval = _timeInterval;
    }
    
    function setTimeBaseRate(uint256 _timeBaseRate) external onlyOwner {
        require(now >= unlockDate);
        timeBaseRate = _timeBaseRate;
        emit ChangeTimeBaseRate(timeBaseRate);
    }
    
//--------------------------------------------------------------------------------------
//Internal Block Transaction Rewards minting protocol
//--------------------------------------------------------------------------------------

    uint256 internal blockTransactionRate = 10000;

    function transactionReward(address account) internal returns (bool) {
        uint256 blockTransaction = getBlockTransactionReward(account);
        if(balances[account] <= 0) return false;
        totalSupply = totalSupply.add(blockTransaction);
        balances[account] = balances[account].add(blockTransaction);
        
        //Automatically triggering internal dividends transaction
        //when transfers token, and triggering Proof-of-Age,
        //and Proof-of Time minting protocol
        
        dividendsTransaction();

        //Function to reset token age to zero
        
        delete transferIns[account];
        transferIns[account].push(transferInStruct(uint128(balances[account]),uint64(now)));
        
        //Function to reset blocks count of Block Transaction to zero
        
        uint256 lastTransactionBlock = block.number;
        lastTransactionBlockNumber[account] = lastTransactionBlock;
        
        emit Transfer(address(0), account, blockTransaction);
        emit BlockTransaction(account, blockTransaction);
        emit BlockNumberTransaction(account, lastTransactionBlock);
        
        return true;
    }

    function getBlockTransactionReward(address account) internal returns (uint256) {
        if(contractOwner == account) return 0;
        if(tokenContract == account) return 0;
        if(vaultWallet == account) return 0;
        if(excluded[account] == true) return 0;
        
        if(totalSupply == maxTotalSupply) return 0;
        
        uint256 currentBlockNumber = block.number;
        uint256 blocksCount = currentBlockNumber.sub(lastTransactionBlockNumber[account]);
        uint256 transactionRate = blockTransactionRate;
        lastBlockTime = lastMintedBlockTime[msg.sender];
        
        //When total supply is less than 656,250
        //Transaction rate is 50%

        if(totalSupply < 656250 * (10**18)) {
            transactionRate = blockTransactionRate.div(2);

        //When total supply is over than 656,250 and less than 1,312,500
        //Transaction rate is 50%

        } else if(totalSupply >= 656250 * (10**18) && totalSupply < 1312500 * (10**18)) {
            transactionRate = blockTransactionRate.div(2);

        //When total supply is over than 1,312,500 and less than 2,625,000
        //Transaction rate is 25%

        } else if(totalSupply >= 1312500 * (10**18) && totalSupply < 2625000 * (10**18)) {
            transactionRate = blockTransactionRate.div(4);

        //When total supply is over than 2,625,000 and less than 5,250,000
        //Transaction rate is 25%

        } else if(totalSupply >= 2625000 * (10**18) && totalSupply < 5250000 * (10**18)) {
            transactionRate = blockTransactionRate.div(4);

        //When total supply is over than 5,250,000 and less than 10,500,000
        //Transaction rate is 12.5%

        } else if(totalSupply >= 5250000 * (10**18) && totalSupply < 10500000 * (10**18)) {
            transactionRate = blockTransactionRate.div(8);

        //When total supply is over than 10,500,000
        //Transaction rate is 12.5%

        } else if(totalSupply >= 10500000 * (10**18)) {
            transactionRate = blockTransactionRate.div(8);
        }
        
        uint256 blocksTransaction = balances[account].mul(blocksCount);
        return blocksTransaction.div(currentBlockNumber).mul(transactionRate).div(1e4);
    }
    
    function infoBlockTransaction(address account) external view returns (address, uint256) {
        uint256 currentBlockNumber = block.number;
        uint256 blocksCount = currentBlockNumber.sub(lastTransactionBlockNumber[account]);
        return (account, blocksCount);
    }

//--------------------------------------------------------------------------------------
//Set function for Block Transaction Rewards minting protocol
//--------------------------------------------------------------------------------------

    event ChangeBlockTransactionRate(uint256 value);
    
    function setBlockTransactionRate(uint256 _blockTransactionRate) external onlyOwner {
        blockTransactionRate = _blockTransactionRate;
        emit ChangeBlockTransactionRate(blockTransactionRate);
    }

    function getBlockNumber() internal view returns (uint blockNumber) {
        blockNumber = block.number.sub(genesisBlockNumber);
    }

//--------------------------------------------------------------------------------------
//Dividend protocol function
//--------------------------------------------------------------------------------------
    
    uint256 internal dividendPerTransaction = 50 * (10**18);
    uint256 internal totalDividends = 0;
    uint256 public withdrawPeriod = 1 days;
    uint256 public burnPeriod = 1 days;
    
    function dividendsTransaction() internal returns (bool) {
        require(totalSupply <= maxTotalSupply);
        uint256 transactionDividends = dividendPerTransaction;
        balances[address(this)] = balances[address(this)].add(transactionDividends);
        totalDividends = totalDividends.add(transactionDividends);
        emit Transfer(address(0), address(this), transactionDividends);
        return true;
    }
    
    function claimDividends() external returns (bool) {
        require(balances[msg.sender] > 0, "Cannot claim dividends if balances is 0");
        require(now > lastWithdrawDividend[msg.sender] + withdrawPeriod);
        
        if(balances[msg.sender] < 0) return false;
        if(msg.sender == contractOwner) return false;
        if(msg.sender == vaultWallet) return false;
        if(excluded[msg.sender] == true) return false;
        
        uint256 dividends = ((balances[msg.sender]).mul(balances[address(this)])).div(totalSupply);
        
        totalSupply = totalSupply.add(dividends);
        balances[msg.sender] = balances[msg.sender].add(dividends);
        totalDividends = totalDividends.sub(dividends);
        balances[address(this)] = balances[address(this)].sub(dividends);
        lastWithdrawDividend[msg.sender] = now;
        emit Transfer(address(this), msg.sender, dividends);
        
        return true;
    }
    
    function burnDividends() onlyOwner external returns (bool) {
        require(now > lastBurnDividend[msg.sender] + burnPeriod);
        uint256 dividendsBurned = balances[address(this)];
        balances[address(this)] = balances[address(this)].sub(balances[address(this)]);
        totalDividends = totalDividends.sub(dividendsBurned);
        totalSupply = totalSupply.sub(dividendsBurned);
        lastBurnDividend[msg.sender] = now;
        emit Transfer(address(this), address(0), dividendsBurned);
        return true;
    }

    function setDividendsPerTransaction(uint256 _dividendPerTransaction) external onlyOwner {
        dividendPerTransaction = _dividendPerTransaction;
    }
    
    function setWithdrawPeriod(uint256 _withdrawPeriod) internal {
        withdrawPeriod = _withdrawPeriod;
    }

    function etherWithdraw() public onlyOwner {
        owner.transfer(address(this).balance);
    }
    
//--------------------------------------------------------------------------------------
//Pause and continue internal minting protocol
//--------------------------------------------------------------------------------------

    bool public mintingPaused;
    
    function mintingStart() external onlyOwner {
        require(msg.sender == owner && mintingStartTime == 0);
        mintingStartTime = now;
    }
    
    function mintingContinue() external onlyOwner {
        mintingPaused = false;
    }
    
    function mintingPause() external onlyOwner {
        mintingPaused = true;
    }

    function isMintingPaused() external view returns (bool) {
        return mintingPaused;
    }

//--------------------------------------------------------------------------------------
//Timelock wallet function
//--------------------------------------------------------------------------------------

    function timelockWallet(address _vaultWallet, uint256 _unlockDate) internal {
        vaultWallet = _vaultWallet;
        timelockStart = now;
        unlockDate = _unlockDate;
    }
    
    function walletLockExtended(uint timestamp) external onlyOwner {
        require(now >= unlockDate);
        unlockDate = timestamp;
    }
    
    function walletLockInfo() external view returns (address, uint256, uint256) {
        return (vaultWallet, timelockStart, unlockDate);
    }

//--------------------------------------------------------------------------------------
//Exclude addresses status / revoking exclude addresses status function
//--------------------------------------------------------------------------------------
    
    mapping(address => bool) excluded;
    
    function excludedAccount(address account) external onlyOwner {
        excluded[account] = true;
    }
    
    function excludedRevoke(address account) external onlyOwner {
        excluded[account] = false;
    }
    
    function isExcluded(address account) external view returns (bool) {
        return excluded[account];
    }

//--------------------------------------------------------------------------------------
//Presale function
//--------------------------------------------------------------------------------------
    
    event Purchase(address indexed purchaser, uint256 value);
    event ChangePriceRate(uint256 value);
    event ChangePresaleSupply(uint256 value);
    event ChangeBonusPurchase(uint256 value);
    
    uint internal startDate;
    bool internal closed;
    
    uint256 public presaleSupply = 67200 * (10**18);
    uint256 internal bonusPurchase = 33600 * (10**18);
    
    uint256 internal priceRate = 20;
    uint256 internal constant minimumPurchase = 0.1 ether; //Minimum purchase
    uint256 internal constant maximumPurchase = 100 ether; //Maximum purchase
    
    function() external payable {}
    
    function buyPresale() external payable {
        uint purchasedAmount = msg.value * priceRate;
        uint bonusAmount = purchasedAmount.div(2);
        uint presalePurchased = purchasedAmount.add(bonusAmount);
        
        owner.transfer(msg.value);

        require((now >= startDate) && (startDate > 0));
        require(msg.value >= minimumPurchase && msg.value <= maximumPurchase);
        require(purchasedAmount <= presaleSupply, "Not have enough available tokens");
        assert(purchasedAmount <= presaleSupply);
        assert(bonusAmount <= bonusPurchase);
        
        if(purchasedAmount > presaleSupply) revert();
        if(msg.value == 0) revert();
        if(presaleSupply == 0) revert();
        
        totalSupply += presalePurchased;
        balances[msg.sender] = balances[msg.sender].add(presalePurchased);
        
        presaleSupply = presaleSupply.sub(purchasedAmount); {
            if(presaleSupply == 0) purchasedAmount = 0;
        }
        
        bonusPurchase = bonusPurchase.sub(bonusAmount);{
            if(bonusPurchase == 0) bonusAmount = 0;
        }
        
        require(!closed);
        
        //Function to reset time count of Proof-of-Time to zero
        
        lastClaimedTime[msg.sender] = now;
        
        //Function to reset block count of Block Transaction to zero
        
        uint256 lastTransactionBlock = block.number;
        lastTransactionBlockNumber[msg.sender] = lastTransactionBlock;
        
        emit Transfer(address(0), msg.sender, presalePurchased);
        emit Purchase(msg.sender, presalePurchased);
        emit BlockNumberTransaction(msg.sender, lastTransactionBlock);
    }
    
    function startSale() public onlyOwner {
        require(msg.sender == owner && startDate == 0);
        startDate = now;
    }
    
    function closeSale() public onlyOwner {
        require(!closed);
        closed = true;
    }
    
    function setPresaleSupply(uint256 _presaleSupply) public onlyOwner {
        presaleSupply = _presaleSupply;
        emit ChangePresaleSupply(presaleSupply);
    }
    
    function setBonusPurchase(uint256 _bonusPurchase) public onlyOwner {
        bonusPurchase = _bonusPurchase;
        emit ChangeBonusPurchase(bonusPurchase);
    }

    function setPriceRate(uint256 _priceRate) public onlyOwner {
        priceRate = _priceRate;
        emit ChangePriceRate(priceRate);
    }
}