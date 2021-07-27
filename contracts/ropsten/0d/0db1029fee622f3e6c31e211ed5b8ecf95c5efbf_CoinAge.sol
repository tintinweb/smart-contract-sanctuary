/**
 *Submitted for verification at Etherscan.io on 2021-07-27
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

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    
    function functionCall(address target, bytes memory data) internal returns (bytes memory){
        require(isContract(target));
        return functionCall(target, data);
    }
    
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory){
        require(isContract(target));
        return functionCallWithValue(target, data, value);
    }
    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory){
        require(isContract(target));
        return functionStaticCall(target, data);
    }
    
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data);
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeIERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)));
        }
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
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed account, address indexed spender, uint256 value);
}

contract TimeLocked {
    address internal vault;
    uint256 internal unlockDate;
    uint256 internal timelockStart;
}

contract ERAprotocol {
    
    //------------------------------------------------------------------------------------
    //ERA minting protocol is authored, constructed and recoded by Azreh Hargun
    //CoinAge function methodology is borrowed and recoded from POS Token ERC20
    //Time age and dividend bearing methodology is originally constructed by Azreh Hargun
    //Transaction reward methodology is borrowed and recoded from Bitcoin Network BEP20
    //------------------------------------------------------------------------------------
    //https://facebook.com/azrehargun
    //https://twitter.com/azrehargun
    //https://github.com/azrehargun
    //------------------------------------------------------------------------------------
    
    uint256 public mintingStartTime;
    uint256 private coinAgeBaseRate;
    
    uint256 private minCoinAge;
    uint256 private maxCoinAge;
    
    uint256 private timeInterval;
    uint256 private timeBaseRate;

    uint256 internal totalBlocksMinted;

    function proofOfAgeMinting() internal returns (bool);
    function proofOfTimeMinting() internal returns (bool);
    function transactionReward(address account) internal returns (bool);
    
    function coinAge() internal view returns (uint);
    function annualCoinAgeRate() internal view returns (uint256);

    event ProofOfAgeMinting(address indexed account, uint256 _coinAgeRewards);
    event ProofOfTimeMinting(address indexed account, uint256 _timeAgeRewards);
    
    event BlockTransaction(address indexed account, uint256 _blockTransaction);
    event BlockNumberTransaction(address indexed account, uint256 _blockNumber);
}

//--------------------------------------------------------------------------------------
//Constructor
//--------------------------------------------------------------------------------------

contract CoinAge is IERC20, Ownable, ERAprotocol, TimeLocked {
    using SafeMath for uint256;
    using Address for address;
    
    string public _name = "CoinAge";
    string public _symbol = "0xCAGE";
    uint8 public _decimals = 18;
    
    uint256 public totalSupply;
    uint256 public maxTotalSupply;
    uint256 private circulatingSupply;
    uint256 private lockedSupply;
    uint256 private genesisSupply;
    
    uint256 private genesisBlockNumber;
    uint256 private genesisStartTime;
    uint256 private lastBlockTime;
    
    uint256 private totalBlocksMinted = 1;
    
    address private tokenContract = address(this);

    //Set owner address

    address private contractOwner = 0x1f6c7479c4Cf953505594EB667FA9CFC9b029f9D;
    
    //Set vault wallet address
    //to locked team and developer token allocations also LP's tokens
    //Vault wallet locked automatically until specified time
    
    address private vaultWallet = 0xB09Ca9ff97E0CD920890DF0845E1b1286348f198;

    //Set unlock date for vault wallet in unix timestamp

    uint256 private unlockDate = 1784764800; //Thu Jul 23 2026 00:00:00 GMT+0000
    uint256 private timelockStart;
    
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowances;
    mapping(address => uint256) lastMintedBlockTime;
    mapping(address => uint256) private lastClaimedTime;
    mapping(address => uint256) private lastTransactionBlockNumber;
    mapping(address => uint256) private lastWithdrawDividend;
    mapping(address => uint256) private lastBurnDividend;
    mapping(address => transferInStruct[]) transferIns;
    
    struct transferInStruct{
        uint128 amount;
        uint64 time;
    }

    constructor() public {
        owner = msg.sender;
        maxTotalSupply = 21000000 * (10**18);
        circulatingSupply = 92400 * (10**18);
        lockedSupply = 10500 * (10**18);
        
        genesisStartTime = now;
        genesisBlockNumber = block.number;
        lastMintedBlockTime[msg.sender] = totalBlocksMinted;
        
        balances[msg.sender] = circulatingSupply;
        balances[0xB09Ca9ff97E0CD920890DF0845E1b1286348f198] = lockedSupply;
        
        genesisSupply = circulatingSupply.add(lockedSupply);
        totalSupply += genesisSupply;
        
        timelockStart = now;
    }
    
    function getBlockNumber() private view returns (uint blockNumber) {
        blockNumber = block.number.sub(genesisBlockNumber);
    }
    
    function totalBlockMinted() private view returns (uint256){
        return totalBlocksMinted;
    }
    
    function name() public view returns (string memory) {
        return _name;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function balanceOf(address account) public view returns (uint256 balance) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        
        //function to trigger and called internal "Proof-of-Age" minting
        //by send transaction to token holder own wallet address
        //with zero amount of tokens
        
        if(msg.sender == recipient && balances[msg.sender] > 0) return proofOfAgeMinting();
        
        //function to trigger and called internal "Proof-of-Time" minting
        //by send transaction to token contract address
        //with zero amount of tokens
        
        if(tokenContract == recipient && balances[msg.sender] > 0) return proofOfTimeMinting();
        
        _transfer(msg.sender, recipient, amount);
        
        return true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        
        if(vaultWallet == sender && now < unlockDate) revert();
        if(vaultWallet == sender && now >= unlockDate) unlockDate = 0;
        
        transactionReward(sender);
        
        balances[sender] = balances[sender].sub(amount); {
            uint256 transactionRewards = getTransactionRewards(sender);
            totalSupply = totalSupply.add(transactionRewards);
            balances[sender] = balances[sender].add(transactionRewards);
            
            //function to reset block count of transaction reward to zero
            
            uint256 lastTransactionBlock = block.number;
            lastTransactionBlockNumber[sender] = lastTransactionBlock;
            emit BlockNumberTransaction(sender, lastTransactionBlock);
        }
        
        transactionReward(recipient);
        
        balances[recipient] = balances[recipient].add(amount); {
            uint256 transactionRewards = getTransactionRewards(recipient);
            totalSupply = totalSupply.add(transactionRewards);
            balances[recipient] = balances[sender].add(transactionRewards);
            
            //function to reset time count of Proof-of-Time to zero
            
            lastClaimedTime[recipient] = now;
            
            //function to reset block count of transaction reward to zero
            
            uint256 lastTransactionBlock = block.number;
            lastTransactionBlockNumber[recipient] = lastTransactionBlock;
            emit BlockNumberTransaction(recipient, lastTransactionBlock);
        }
        
        lastClaimedTime[recipient] = now;
        
        emit Transfer(sender, recipient, amount);
        
        //function to reset coin age of Proof-of-Age to zero
        
        if(transferIns[sender].length > 0) delete transferIns[sender];
        uint64 _now = uint64(now);
        transferIns[sender].push(transferInStruct(uint128(balances[sender]),_now));
        transferIns[recipient].push(transferInStruct(uint128(amount),_now));
    }

    function allowance(address account, address spender) public view returns (uint256) {
        return allowances[account][spender];
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, allowances[sender][msg.sender].sub(amount));
        return true;
    }

    function mint(uint256 amount) public onlyOwner returns (bool) {
        require(totalSupply <= maxTotalSupply);
        _mint(msg.sender, amount);
        return true;
    }

    function _mint(address account, uint256 amount) private {
        require(account != address(0), "ERC20: mint to the zero address");
        totalSupply = totalSupply.add(amount);
        balances[account] = balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function burn(address account, uint256 amount) private {
        require(account != address(0), "ERC20: burn from the zero address");
        balances[account] = balances[account].sub(amount);
        totalSupply = totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner,address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function destroySmartContract(address payable account) public onlyOwner {
        require(msg.sender == owner, "You are not the owner");
        selfdestruct(account);
    }

//--------------------------------------------------------------------------------------
//Internal Proof-of-Age minting protocol
//--------------------------------------------------------------------------------------

    uint256 public mintingStartTime; //Minting start time
    uint256 internal coinAgeBaseRate = 10**17; //Coin age base rate minting
    uint256 internal minCoinAge = 1 days; //Minimum Age for minting : 1 day
    uint256 internal maxCoinAge = 90 days; //Age of full weight : 90 days
    
    function claimCoinAgeRewards() public returns (bool) {
        require(balances[msg.sender] > 0, "Cannot claim if balances is 0");
        require((now >= mintingStartTime) && (mintingStartTime > 0));
        require(mintingPaused == false);
        if(mintingPaused == true) return false;
        
        if(totalSupply == maxTotalSupply) return false;
        
        if(contractOwner == msg.sender) revert();
        if(vaultWallet == msg.sender) revert();
        if(excluded[msg.sender] == true) revert();
        
        proofOfAgeMinting();
    }
    
    function proofOfAgeMinting() internal returns (bool) {
        if(balances[msg.sender] <= 0) return false;
        if(transferIns[msg.sender].length <= 0) return false;
        
        uint256 coinAgeRewards = getProofOfAgeRewards(msg.sender);
        
        totalSupply = totalSupply.add(coinAgeRewards);
        balances[msg.sender] = balances[msg.sender].add(coinAgeRewards);
        
        //function to reset coin age of Proof-of-Age to zero
        
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));

        emit Transfer(address(0), msg.sender, coinAgeRewards);
        emit ProofOfAgeMinting(msg.sender, coinAgeRewards);
        
        totalBlocksMinted++;
        
        //function to mint dividends when trigger and called "Proof-of-Age" minting
        
        dividendsTransaction();
        
        //function to called "Transaction rewards" when trigger and called "Proof-of-Age" minting
        
        transactionReward(msg.sender); {
            uint256 transactionRewards = getTransactionRewards(msg.sender);
            totalSupply = totalSupply.add(transactionRewards);
            balances[msg.sender] = balances[msg.sender].add(transactionRewards);
        }
        
        //function to reset block count of transaction reward to zero
        
        uint256 lastTransactionBlock = block.number;
        lastTransactionBlockNumber[msg.sender] = lastTransactionBlock;
        emit BlockNumberTransaction(msg.sender, lastTransactionBlock);
            
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

        if(contractOwner == msg.sender) return 0;
        if(vaultWallet == msg.sender) return 0;
        if(excluded[msg.sender] == true) return 0;
        
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
            if(_now < uint(transferIns[account][i].time).add(minCoinAge)) continue;
            uint coinAgeSeconds = _now.sub(uint(transferIns[account][i].time));
            if(coinAgeSeconds > maxCoinAge) coinAgeSeconds = maxCoinAge;
            _coinAge = _coinAge.add(uint(transferIns[account][i].amount) * coinAgeSeconds.div(1 days));
        }
    }
    
    function infoTokenAgeMinting(address account) public view returns (address, uint256, uint256, uint256) {
        uint _now = now;
        uint _coinAge = getCoinAge(account, _now);
        return (account, _coinAge, minCoinAge, maxCoinAge);
    }

//--------------------------------------------------------------------------------------
//Internal Proof-of-Time minting protocol
//--------------------------------------------------------------------------------------

    uint256 private timeInterval = 31556926; //1 years unix timestamp = 31556926 seconds
    uint256 private timeBaseRate = 10000; //Default time minting rate is 100%
    
    function claimTimeAgeRewards() public returns (bool) {
        require(balances[msg.sender] > 0, "Cannot claim if balances is 0");
        require((now >= mintingStartTime) && (mintingStartTime > 0));
        require(mintingPaused == false);
        if(mintingPaused == true) return false;
        
        if(totalSupply == maxTotalSupply) return false;
        
        if(contractOwner == msg.sender) revert();
        if(vaultWallet == msg.sender) revert();
        if(excluded[msg.sender] == true) revert();
        
        proofOfTimeMinting();
    }
    
    function proofOfTimeMinting() internal returns (bool) {
        if(balances[msg.sender] <= 0) return false;
        
        uint256 timeRewards = getProofOfTimeRewards(msg.sender);
        
        totalSupply = totalSupply.add(timeRewards);
        balances[msg.sender] = balances[msg.sender].add(timeRewards);

        //Function to reset coin age of Proof-of-Age to zero
        
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));

        emit Transfer(address(0), msg.sender, timeRewards);
        emit ProofOfTimeMinting(msg.sender, timeRewards);
        
        totalBlocksMinted++;
        
        //function to mint dividends when trigger and called "Proof-of-Time" minting
        
        dividendsTransaction();
        
        //function to called "Transaction rewards" when trigger and called "Proof-of-Time" minting
        
        transactionReward(msg.sender); {
            uint256 transactionRewards = getTransactionRewards(msg.sender);
            totalSupply = totalSupply.add(transactionRewards);
            balances[msg.sender] = balances[msg.sender].add(transactionRewards);
        }
        
        //function to reset block count of transaction reward to zero
        
        uint256 lastTransactionBlock = block.number;
        lastTransactionBlockNumber[msg.sender] = lastTransactionBlock;
        emit BlockNumberTransaction(msg.sender, lastTransactionBlock);
        
        //function to reset time count of Proof-of-Time to zero
        
        lastClaimedTime[msg.sender] = now;
        
        return true;
    }

    function getProofOfTimeRewards(address account) internal returns (uint256) {
        require((now >= mintingStartTime) && (mintingStartTime > 0));
        require(mintingPaused == false);
        if(mintingPaused == true) return 0;

        if(totalSupply == maxTotalSupply) return 0;
        
        if(contractOwner == account) return 0;
        if(vaultWallet == account) return 0;
        if(excluded[account] == true) return 0;
        
        uint256 timeCount = now.sub(lastClaimedTime[account]);
        lastBlockTime = lastMintedBlockTime[account];
        uint256 timeMintingRate = timeBaseRate;
        
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
    
    function infoTimeMinting(address account) public view returns (address, uint256, uint256) {
        uint256 timeCount = now.sub(lastClaimedTime[account]);
        return(account, timeCount, timeInterval);
    }

//--------------------------------------------------------------------------------------
//Set function for Proof-of-Time minting protocol
//--------------------------------------------------------------------------------------
    
    event ChangeTimeBaseRate(uint256 value);
    
    function setTimeInterval(uint256 _timeInterval) public onlyOwner {
        require(now >= unlockDate);
        timeInterval = _timeInterval;
    }
    
    function setTimeBaseRate(uint256 _timeBaseRate) public onlyOwner {
        require(now >= unlockDate);
        timeBaseRate = _timeBaseRate;
        emit ChangeTimeBaseRate(timeBaseRate);
    }

//--------------------------------------------------------------------------------------
//Internal Transaction Rewards
//--------------------------------------------------------------------------------------

    event ChangeTransactionBaseRate(uint256 value);
    
    uint256 private transactionBaseRate = 1250; //Default transaction rate is 12.5%
    
    function transactionReward(address account) internal returns (bool) {
        uint256 transactionRewards = getTransactionRewards(account);
        totalSupply = totalSupply.add(transactionRewards);
        balances[account] = balances[account].add(transactionRewards);

        //function to reset token age of Proof-of-Age to zero
        
        delete transferIns[account];
        transferIns[account].push(transferInStruct(uint128(balances[account]),uint64(now)));

        emit Transfer(address(0), account, transactionRewards);
        emit BlockTransaction(account, transactionRewards);
        
        //function to reset block count of transaction reward to zero
        
        uint256 lastTransactionBlock = block.number;
        lastTransactionBlockNumber[account] = lastTransactionBlock;
        emit BlockNumberTransaction(account, lastTransactionBlock);
        
        totalBlocksMinted++;
        
        return true;
    }

    function getTransactionRewards(address account) internal returns (uint256) {
        if(contractOwner == account) return 0;
        if(vaultWallet == account) return 0;
        if(excluded[account] == true) return 0;
        
        if(totalSupply == maxTotalSupply) return 0;
        
        uint256 currentBlockNumber = block.number;
        lastBlockTime = lastMintedBlockTime[account];
        uint256 blockCount = currentBlockNumber.sub(lastTransactionBlockNumber[account]);
        uint256 transactionRate = transactionBaseRate;
        
        //When total supply is less than 656,250
        //Transaction rate is 25%

        if(totalSupply < 656250 * (10**18)) {
            transactionRate = transactionBaseRate.mul(2);

        //When total supply is over than 656,250 and less than 1,312,500
        //Transaction rate is 25%

        } else if(totalSupply >= 656250 * (10**18) && totalSupply < 1312500 * (10**18)) {
            transactionRate = transactionBaseRate.mul(2);

        //When total supply is over than 1,312,500 and less than 2,625,000
        //Transaction rate is 12.5%

        } else if(totalSupply >= 1312500 * (10**18) && totalSupply < 2625000 * (10**18)) {
            transactionRate = transactionBaseRate.mul(1);

        //When total supply is over than 2,625,000 and less than 5,250,000
        //Transaction rate is 12.5%

        } else if(totalSupply >= 2625000 * (10**18) && totalSupply < 5250000 * (10**18)) {
            transactionRate = transactionBaseRate.mul(1);

        //When total supply is over than 5,250,000 and less than 10,500,000
        //Transaction rate is 6.25%

        } else if(totalSupply >= 5250000 * (10**18) && totalSupply < 10500000 * (10**18)) {
            transactionRate = transactionBaseRate.div(2);

        //When total supply is over than 10,500,000
        //Transaction rate is 6.25%

        } else if(totalSupply >= 10500000 * (10**18)) {
            transactionRate = transactionBaseRate.div(2);
        }
        
        return balances[account].mul(transactionRate).mul(blockCount).div(currentBlockNumber).div(1e4);
    }
    
    function infoTransaction(address account) public view returns (address, uint256) {
        uint256 currentBlockNumber = block.number;
        uint256 blockCount = currentBlockNumber.sub(lastTransactionBlockNumber[account]);
        return(account, blockCount);
    }
    
    function setTransactionBaseRate(uint256 _transactionBaseRate) public onlyOwner {
        transactionBaseRate = _transactionBaseRate;
        emit ChangeTransactionBaseRate(transactionBaseRate);
    }

//--------------------------------------------------------------------------------------
//Dividend protocol function
//--------------------------------------------------------------------------------------
    
    uint256 private dividendPerTransaction = 10 * (10**18);
    uint256 private totalDividends = 0;
    uint256 public withdrawPeriod = 1 days;
    uint256 public burnPeriod = 1 days;
    
    function dividendsTransaction() private returns (bool) {
        if(totalSupply == maxTotalSupply) return false;
        uint256 transactionDividends = dividendPerTransaction;
        balances[address(this)] = balances[address(this)].add(transactionDividends);
        totalDividends = totalDividends.add(transactionDividends);
        emit Transfer(address(0), address(this), transactionDividends);
        return true;
    }
    
    function claimDividends() public returns (bool) {
        require(balances[msg.sender] > 0);
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
        
        emit Transfer(address(this), msg.sender, dividends);
        
        lastWithdrawDividend[msg.sender] = now;
        
        return true;
    }
    
    function burnDividends() onlyOwner public returns (bool) {
        require(now > lastBurnDividend[msg.sender] + burnPeriod);
        uint256 dividendsBurned = balances[address(this)];
        
        balances[address(this)] = balances[address(this)].sub(balances[address(this)]);
        totalDividends = totalDividends.sub(dividendsBurned);
        totalSupply = totalSupply.sub(dividendsBurned);
        
        emit Transfer(address(this), address(0), dividendsBurned);
        
        lastBurnDividend[msg.sender] = now;
        
        return true;
    }

    function setDividendsPerTransaction(uint256 _dividendPerTransaction) public onlyOwner {
        dividendPerTransaction = _dividendPerTransaction;
    }
    
    function setWithdrawPeriod(uint256 timestamp) public onlyOwner {
        withdrawPeriod = timestamp;
    }
    
    function setBurnPeriod(uint256 timestamp) public onlyOwner {
        burnPeriod = timestamp;
    }

    function etherWithdraw() public onlyOwner {
        owner.transfer(address(this).balance);
    }
    
//--------------------------------------------------------------------------------------
//Pause and continue internal minting protocol
//--------------------------------------------------------------------------------------

    bool public mintingPaused;
    
    function mintingStart() public onlyOwner {
        require(msg.sender == owner && mintingStartTime == 0);
        mintingStartTime = now;
    }
    
    function mintingContinue() public onlyOwner {
        mintingPaused = false;
    }
    
    function mintingPause() public onlyOwner {
        mintingPaused = true;
    }

    function isMintingPaused() public view returns (bool) {
        return mintingPaused;
    }

//--------------------------------------------------------------------------------------
//Timelock wallet function
//--------------------------------------------------------------------------------------

    function timelockWallet(address _vaultWallet, uint256 _unlockDate) private {
        vaultWallet = _vaultWallet;
        timelockStart = now;
        unlockDate = _unlockDate;
    }
    
    function walletLockExtended(uint timestamp) public onlyOwner {
        require(now >= unlockDate);
        unlockDate = timestamp;
    }
    
    function walletLockInfo() public view returns (address, uint256, uint256) {
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
    
    uint private startDate;
    bool private closed;
    
    uint256 private presaleSupply = 71400 * (10**18);
    uint256 private bonusPurchase = 35700 * (10**18);
    
    uint256 private priceRate = 20;
    uint256 private constant minimumPurchase = 0.1 ether; //Minimum purchase
    uint256 private constant maximumPurchase = 100 ether; //Maximum purchase
    
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
        
        emit Transfer(address(0), msg.sender, presalePurchased);
        emit Purchase(msg.sender, presalePurchased);
        
        totalBlocksMinted++;
        
        //Function to reset time count of Proof-of-Time to zero
        
        lastClaimedTime[msg.sender] = now;
        
        //function to reset block count of transaction reward to zero
        
        uint256 lastTransactionBlock = block.number;
        lastTransactionBlockNumber[msg.sender] = lastTransactionBlock;
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