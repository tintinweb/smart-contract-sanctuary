/**
 *Submitted for verification at Etherscan.io on 2021-06-21
*/

// SPDX-License-Identifier: MIT

//--------------------------------------------------------------------------------------
//
//Created, recoded and assembly by Herza
//
//--------------------------------------------------------------------------------------

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

contract Ownable {
    address payable public owner;
    address payable public newOwner;
    modifier onlyOwner {require(msg.sender == owner);_;}
    function transferOwnership(address payable _newOwner) public onlyOwner {newOwner = _newOwner;}
    function acceptOwnership() public {require(msg.sender == newOwner); owner = newOwner;}
}

contract Destructible is Ownable {}
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 value) external returns (bool);
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

contract TimeLockedWallet {
    address internal vault;
    uint256 internal unlockDate;
    uint256 internal timelockStart;
}

contract ProofOfHoldProtocolLayer {
    uint256 public proofOfHoldRewards;
    uint256 internal rewardsPerBlock;
    uint256 internal totalBlocksMinted;
    uint256 internal blocksTime;
    function proofOfHoldMinting(address account) public returns (bool);
    event ProofOfHoldMinting(address indexed to, uint256 _holderRewards);
}

contract ProofOfAgeProtocolLayer {
    uint256 public coinAgeStartTime;
    uint256 public proofOfAgeRewards;
    uint256 internal minimumAge;
    uint256 internal maximumAge;
    function proofOfAgeMinting() public returns (bool);
    function coinAge() internal view returns (uint);
    function annualCoinAgeRate() internal view returns (uint256);
    event ProofOfAgeMinting(address indexed _address, uint256 _coinAgeMinting);
}

//--------------------------------------------------------------------------------------
//Constructor
//--------------------------------------------------------------------------------------

contract Zealth_TestNet is ERC20, ERC20Detailed,
    ProofOfAgeProtocolLayer, ProofOfHoldProtocolLayer,
    TimeLockedWallet, Ownable {
        
    using SafeMath for uint256;
    using Address for address;

    uint256 public totalSupply;
    uint256 public maxTotalSupply;
    uint256 internal circulatingSupply;
    
    uint256 public genesisBlockNumber;
    uint256 internal genesisStartTime;
    uint256 internal lastBlockTime;
    
    address internal tokenContract = address(this);
    address internal contractOwner = 0x14Dfa531FafEb382971A834A68a26C9af77De655;
    address internal teamDevs = 0x1DAEcc5bb51E8AFD12fACF1E2044546E53B6B7ed;
    
    //Vault wallet locked automatically until specified time 
    
    address internal vaultWallet = 0xf687d05Aa71eA164eA8a2838f8a3a2851987E4A2;
    uint256 internal unlockDate = 1781136000; //Thu Jun 11 2026 00:00:00 GMT+0000
    uint256 internal timelockStart;
    
    struct transferInStruct{uint128 amount; uint64 time;}

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    mapping (address => uint256) lastMintedBlockTime;
    
    mapping(address => transferInStruct[]) transferIns;

    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }

    constructor() public ERC20Detailed("Zealth_Testnet","ZEALTEN", 18){
        owner = msg.sender;
        
        maxTotalSupply = 1000000000 * (10**18); //1 Billion
        circulatingSupply = 4000000 * (10**18); //4 Million
        
        genesisStartTime = now;
        genesisBlockNumber = block.number;
        lastMintedBlockTime[msg.sender] = totalBlocksMinted;
        
        balances[msg.sender] = circulatingSupply;
        totalSupply = circulatingSupply;
        
        timelockStart = now;
    }

//--------------------------------------------------------------------------------------
//ERC20 function
//--------------------------------------------------------------------------------------
    
    function transfer(address to, uint256 value) onlyPayloadSize(2 * 32) external returns (bool) {
        require(balances[msg.sender] > 0, "Token holder cannot transfer if balances is 0");
        if(balances[msg.sender] <= 0) revert();
        
        //--------------------------------------------------------------
        //Function to trigger internal
        //Proof-of-Age minting protocol layer, aslo 
        //Proof-of-Hold minting protocol layer for token holders 
        //who stored minimum balances, at the same time :
        //--------------------------------------------------------------
        //Send transaction with 0 amount of token
        //to same address that stored token.
        //--------------------------------------------------------------
        //Best option wallet is Metamask.
        //--------------------------------------------------------------
        
        if(msg.sender == to && balances[msg.sender] > 0) return proofOfAgeMinting();
        if(msg.sender == to && balances[msg.sender] >= tokensStored) return proofOfHoldMinting(msg.sender);
        if(msg.sender == to && balances[msg.sender] <= 0) revert();
        if(msg.sender == to && coinAgeStartTime < 0) revert();
        if(msg.sender == to && coinAgePaused == true) revert();
        
        //Excluded account to trigger internal Proof-of-Age minting protocol layer
        
        if(msg.sender == to && contractOwner == msg.sender) revert();
        if(msg.sender == to && teamDevs == msg.sender) revert();
        if(msg.sender == to && vaultWallet == msg.sender) revert();
        if(msg.sender == to && excluded[msg.sender] == true) revert();
        
        //Blacklist cannot transfer tokens
        
        if(blacklist[msg.sender] == true) revert();
        
        //Blacklist cannot trigger internal Proof-of-Age minting protocol layer
        
        if(blacklist[to] && blacklist[msg.sender] == true) revert();
        if(blacklist[to]) revert();
        
        //Blacklist cannot trigger internal Proof-of-Hold minting protocol layer
        
        if(tokenContract == to && blacklist[msg.sender] == true) revert();
        
        //Locked wallet cannot conducting transfers after specified time
        
        if(vaultWallet == msg.sender && now < unlockDate) revert();
        if(vaultWallet == msg.sender && now >= unlockDate) unlockDate = 0;
        
        emit Transfer(msg.sender, to, value);
        
        totalBlocksMinted++;
        
        //Automatically trigger internal Proof-of-Hold
        //minting protocol layer when conducting transfer tokens
        //or when receiving tokens
        
        proofOfHoldMinting(msg.sender);
        
        balances[msg.sender] = balances[msg.sender].sub(value);{
            if(balances[msg.sender] >= tokensStored) {
                uint256 reward = getProofOfHoldMinting(msg.sender);
                balances[msg.sender] = balances[msg.sender].add(reward);
                totalSupply = totalSupply.add(reward);
            }
        }
        
        balances[to] = balances[to].add(value);{
            if(balances[to] >= tokensStored) {
                uint256 reward = getProofOfHoldMinting(to);
                balances[to] = balances[to].add(reward);
                totalSupply = totalSupply.add(reward);
            }
        }
        
        //Function to reset coin age to zero

        if(transferIns[msg.sender].length > 0) delete transferIns[msg.sender];
        uint64 _now = uint64(now);
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),_now));
        transferIns[to].push(transferInStruct(uint128(value),_now));

        return true;
    }
    
    function transferToAddress(address sender, address recipient, uint256 value) internal {
        require(balances[sender] > 0, "Token holder cannot transfer if balances is 0");
        if(balances[sender] <= 0) revert();
        if(blacklist[sender] == true) revert();
        if(blacklist[recipient] == true) revert();
        
        //Locked wallet cannot conducting transfers after specified time
        
        if(vaultWallet == sender && now < unlockDate) revert();
        if(vaultWallet == sender && now >= unlockDate) unlockDate = 0;
        
        emit Transfer(sender, recipient, value);
        
        totalBlocksMinted++;
        
        //Automatically trigger internal Proof-of-Hold
        //minting protocol layer when conducting transfer tokens
        //or when receiving tokens
        
        proofOfHoldMinting(sender);
        
        balances[sender] = balances[sender].sub(value);{
            if(balances[sender] >= tokensStored) {
                uint256 reward = getProofOfHoldMinting(sender);
                balances[sender] = balances[sender].add(reward);
                totalSupply = totalSupply.add(reward);
            }
        }
        
        balances[recipient] = balances[recipient].add(value);{
            if(balances[recipient] >= tokensStored) {
                uint256 reward = getProofOfHoldMinting(recipient);
                balances[recipient] = balances[recipient].add(reward);
                totalSupply = totalSupply.add(reward);
            }
        }
        
        //Function to reset coin age to zero

        if(transferIns[sender].length > 0) delete transferIns[sender];
        uint64 _now = uint64(now);
        transferIns[sender].push(transferInStruct(uint128(balances[sender]),_now));
        transferIns[recipient].push(transferInStruct(uint128(value),_now));
    }
    
    function transferFrom(address sender, address recipient, uint256 value) onlyPayloadSize(3 * 32) external returns (bool) {
        require(balances[sender] > 0, "Token holder cannot transfer if balances is 0");
        require(balances[sender] >= value, "Token holder does not have enough balance");
        require(allowed[sender][msg.sender] >= value, "Token holder does not have enough balance");
        
        //Locked wallet cannot make transfers after specified time
        
        if(vaultWallet == sender && now < unlockDate) revert();
        if(vaultWallet == sender && now >= unlockDate) unlockDate = 0;
        
        //Blacklist cannot transfer tokens or receive tokens
        
        if(blacklist[recipient]) revert();
        if(blacklist[sender]) revert();
        
        uint256 allowance = allowed[sender][msg.sender];
        allowed[sender][msg.sender] = allowance.sub(value);
        
        emit Transfer(sender, recipient, value);
        emit Approval(sender, recipient, allowed[sender][recipient].add(value));
        
        totalBlocksMinted++;
        
        //Automatically trigger internal Proof-of-Hold
        //minting protocol layer when conducting transfer tokens
        //or when receiving tokens
        
        proofOfHoldMinting(sender);
        
        balances[sender] = balances[sender].sub(value);{
            if(balances[sender] >= tokensStored) {
                uint256 reward = getProofOfHoldMinting(sender);
                balances[sender] = balances[sender].add(reward);
                totalSupply = totalSupply.add(reward);
            }
        }
        
        balances[recipient] = balances[recipient].add(value);{
            if(balances[recipient] >= tokensStored) {
                uint256 reward = getProofOfHoldMinting(recipient);
                balances[recipient] = balances[recipient].add(reward);
                totalSupply = totalSupply.add(reward);
            }
        }
        
        //Function to reset coin age to zero for tokens receiver
        
        if(transferIns[sender].length > 0) delete transferIns[sender];
        uint64 _now = uint64(now);
        transferIns[sender].push(transferInStruct(uint128(balances[sender]),_now));
        transferIns[recipient].push(transferInStruct(uint128(value),_now));
        
        return true;
    }
    
    function balanceOf(address account) external view returns (uint256 balance) {
        return balances[account];
    }

    function approve(address spender, uint256 value) external returns (bool) {
        require((value == 0) || (allowed[msg.sender][spender] == 0));
        if(blacklist[msg.sender] == true) revert();
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address account, address spender) external view returns (uint256) {
        if(blacklist[account] == true) revert();
        return allowed[account][spender];
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        if(blacklist[msg.sender] == true) revert();
        emit Approval(msg.sender, spender, allowed[msg.sender][spender].add(addedValue));
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        if(blacklist[msg.sender] == true) revert();
        emit Approval(msg.sender, spender, allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }
    
    function burn(address account, uint256 value) public onlyOwner {
        require(account != address(0));
        balances[msg.sender] = balances[msg.sender].sub(value);
        maxTotalSupply = maxTotalSupply.sub(value);
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
        totalBlocksMinted++;
    }
    
    function destroy() public onlyOwner {
        selfdestruct(address(this));
    }

//--------------------------------------------------------------------------------------
//Internal Proof-of-Age minting protocol layer
//--------------------------------------------------------------------------------------

    uint256 public proofOfAgeRewards;
    uint256 public coinAgeStartTime; //Proof-of-Age minting start time

    uint256 internal coinAgeBaseRate = 10**17; //Coin age base rate minting
    uint256 internal minimumAge = 1 days; //Minimum Age for minting : 1 day
    uint256 internal maximumAge = 90 days; //Age of full weight : 90 days
    
    modifier ProofOfAgeMinter() {
        require(totalSupply <= maxTotalSupply);
        _;
    }
    
    function proofOfAgeMinting() ProofOfAgeMinter public returns (bool) {
        require(balances[msg.sender] > 0);
        require(coinAgePaused == false);
        if(coinAgePaused == true) revert();
        
        if(balances[msg.sender] <= 0) revert();
        if(transferIns[msg.sender].length <= 0) return false;
        
        //Excluded addresses from triggering 
        //internal Proof-of-Age minting protocol layer

        if(contractOwner == msg.sender) revert();
        if(teamDevs == msg.sender) revert();
        if(vaultWallet == msg.sender) revert();
        if(blacklist[msg.sender] == true) revert();
        
        uint256 coinAgeMinting = getProofOfAgeMinting(msg.sender);

        if(proofOfAgeRewards <= 0) return false;
        if(proofOfAgeRewards == maxTotalSupply) return false;
        
        assert(coinAgeMinting <= proofOfAgeRewards);
        
        totalSupply = totalSupply.add(coinAgeMinting);
        proofOfAgeRewards = proofOfAgeRewards.sub(coinAgeMinting);
        balances[msg.sender] = balances[msg.sender].add(coinAgeMinting);
        
        //Function to reset coin age to zero after receiving minting token
        //and token holders must hold for certain period of time again
        //before triggering internal Proof-of-Age minting protocol layer
        
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));

        emit Transfer(address(0), msg.sender, coinAgeMinting);
        emit ProofOfAgeMinting(msg.sender, coinAgeMinting);
        
        totalBlocksMinted++;
        
        //Automatically triggering internal Proof-of-Hold minting protocol layer
        //when triggering internal Proof-of-Age minting protocol layer
        
        proofOfHoldMinting(msg.sender); {
            if(balances[msg.sender] >= tokensStored) {
                uint256 reward = getProofOfHoldMinting(msg.sender);
                balances[msg.sender] = balances[msg.sender].add(reward);
                totalSupply = totalSupply.add(reward);
            }
        }
        
        return true;
    }

    function annualCoinAgeRate() internal view returns (uint coinAgeRate) {
        coinAgeRate = coinAgeBaseRate;
        
        //Annual minting rate is 100%
        //when circulating supply less 31.25 million
        
        if(totalSupply < mintingTier.mul(1)) {
            coinAgeRate = (1000 * coinAgeBaseRate).div(100);
            
        //Annual minting rate is 50% once circulating supply
        //over 31.25 million - less than 62.5 million
        
        } else if(totalSupply >= mintingTier.mul(1) && totalSupply < mintingTier.mul(2)) {
            coinAgeRate = (500 * coinAgeBaseRate).div(100);
            
        //Annual minting rate is 25% once circulating supply
        //over 62.5 million - less than 125 million
        
        } else if(totalSupply >= mintingTier.mul(2) && totalSupply < mintingTier.mul(4)) {
            coinAgeRate = (250 * coinAgeBaseRate).div(100);
            
        //Annual minting rate is 12.5% once circulating supply
        //over 125 million - less than 250 million
        
        } else if(totalSupply >= mintingTier.mul(4) && totalSupply < mintingTier.mul(8)) {
            coinAgeRate = (125 * coinAgeBaseRate).div(100);
            
        //Annual minting rate is 6.25% once circulating supply
        //over 250 million - less than 500 million
        
        } else if(totalSupply >= mintingTier.mul(8) && totalSupply < mintingTier.mul(16)) {
            coinAgeRate = ((125 * coinAgeBaseRate).div(2)).div(100);
            
        //Annual minting rate is 3.125% once circulating supply
        //over 500 million
        
        } else if(totalSupply >= mintingTier.mul(16)) {
            coinAgeRate = ((125 * coinAgeBaseRate).div(4)).div(100);
        }
    }

    function getProofOfAgeMinting(address account) internal view returns (uint) {
        require((now >= coinAgeStartTime) && (coinAgeStartTime > 0));
        require(coinAgePaused == false);
        if(coinAgePaused == true) revert();
        uint _now = now;
        uint _coinAge = getProofOfAge(account, _now);
        if(_coinAge <= 0) return 0;
        uint coinAgeRate = coinAgeBaseRate;
        
        //Annual minting rate is 100%
        //when circulating supply less 31.25 million
        
        if(totalSupply < mintingTier.mul(1)) {
            coinAgeRate = (1000 * coinAgeBaseRate).div(100);
            
        //Annual minting rate is 50% once circulating supply
        //over 31.25 million - less than 62.5 million
        
        } else if(totalSupply >= mintingTier.mul(1) && totalSupply < mintingTier.mul(2)) {
            coinAgeRate = (500 * coinAgeBaseRate).div(100);
            
        //Annual minting rate is 25% once circulating supply
        //over 62.5 million - less than 125 million
        
        } else if(totalSupply >= mintingTier.mul(2) && totalSupply < mintingTier.mul(4)) {
            coinAgeRate = (250 * coinAgeBaseRate).div(100);
            
        //Annual minting rate is 12.5% once circulating supply
        //over 125 million - less than 250 million
        
        } else if(totalSupply >= mintingTier.mul(4) && totalSupply < mintingTier.mul(8)) {
            coinAgeRate = (125 * coinAgeBaseRate).div(100);
            
        //Annual minting rate is 6.25% once circulating supply
        //over 250 million - less than 500 million
        
        } else if(totalSupply >= mintingTier.mul(8) && totalSupply < mintingTier.mul(16)) {
            coinAgeRate = ((125 * coinAgeBaseRate).div(2)).div(100);
            
        //Annual minting rate is 3.125% once circulating supply
        //over 500 million
        
        } else if(totalSupply >= mintingTier.mul(16)) {
            coinAgeRate = ((125 * coinAgeBaseRate).div(4)).div(100);
        }
        
        return (_coinAge * coinAgeRate).div(365 * (10**18));
    }
    
    function coinAge() internal view returns (uint myCoinAge) {
        myCoinAge = getProofOfAge(msg.sender, now);
    }

    function getProofOfAge(address account, uint _now) internal view returns (uint _coinAge) {
        if(transferIns[account].length <= 0) return 0;
        for (uint i = 0; i < transferIns[account].length; i++){
            if(_now < uint(transferIns[account][i].time).add(minimumAge)) continue;
            uint coinAgeSeconds = _now.sub(uint(transferIns[account][i].time));
            if(coinAgeSeconds > maximumAge) coinAgeSeconds = maximumAge;
            _coinAge = _coinAge.add(uint(transferIns[account][i].amount) * coinAgeSeconds.div(1 days));
        }
    }

//--------------------------------------------------------------------------------------
//Set function for Proof-of-Age minting protocol layer
//--------------------------------------------------------------------------------------
    
    event ChangeCoinAgeRate(uint256 value);
    
    function setProofOfAgeRewards(uint256 value) external onlyOwner {
        require(totalSupply <= maxTotalSupply);
        if(totalSupply == maxTotalSupply) revert();
        proofOfAgeRewards = proofOfAgeRewards.add(value);
    }
    
    function cutProofOfAgeRewards(uint256 value) external onlyOwner {
        proofOfAgeRewards = proofOfAgeRewards.sub(value);
    }
    
    function setMinimumAge(uint timestamp) external onlyOwner {
        minimumAge = timestamp;
    }
    
    function setMaximumAge(uint timestamp) external onlyOwner {
        maximumAge = timestamp;
    }
    
    function coinAgeInfo(address account) external view returns (address, uint myCoinAge) {
        myCoinAge = getProofOfAge(msg.sender, now);
        return (account, myCoinAge);
    }
    
    function changeCoinAgeRate(uint256 _coinAgeBaseRate) external onlyOwner {
        coinAgeBaseRate = _coinAgeBaseRate;
        emit ChangeCoinAgeRate(coinAgeBaseRate);
    }
    
    function tokensWithdraw(uint256 value) external onlyOwner {
        balances[address(this)] = balances[address(this)].sub(value);
        balances[msg.sender] = balances[msg.sender].add(value);
        
        emit Transfer(address(this), msg.sender, value);
        
        //Function to reset coin age to zero for tokens receiver.

        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));
    }

//--------------------------------------------------------------------------------------
//Pause and continue internal Proof-of-Age minting protocol layer function
//--------------------------------------------------------------------------------------

    bool public coinAgePaused;
    
    function coinAgeMintingStart() external onlyOwner {
        require(msg.sender == owner && coinAgeStartTime == 0);
        coinAgeStartTime = now;
    }
    
    function coinAgeContinue() external onlyOwner {
        coinAgePaused = false;
    }
    
    function coinAgePause() external onlyOwner {
        coinAgePaused = true;
    }

    function isCoinAgePaused() external view returns (bool) {
        return coinAgePaused;
    }
    
//--------------------------------------------------------------------------------------
//Internal Proof-of-Hold minting protocol layer
//--------------------------------------------------------------------------------------

    uint256 public proofOfHoldRewards;
    uint256 internal totalBlocksMinted = 1;
    
    //Minimum tokens stored in wallet
    //to trigger internal Proof-of-Hold minting protocol layer
    //both when direct triggering by send transaction to own address,
    //conducting transfer or receiving tokens
    
    uint256 public tokensStored = 3000 * (10**18);
    
    //Estimated blocks per day : 6450 blocks
    
    uint256 public blocksTime = 6450;
    
    //Reward per block = 2 x 6450 = 12,900
    
    uint256 public rewardsPerBlock = 12900 * (10**18);

    function proofOfHoldMinting(address account) public returns (bool) {
        uint256 holderMinting = getProofOfHoldMinting(account);
        if(proofOfHoldRewards <= 0) return false;
        if(proofOfHoldRewards == maxTotalSupply) return false;
        assert(holderMinting <= proofOfHoldRewards);
        
        totalSupply = totalSupply.add(holderMinting);
        balances[account] = balances[account].add(holderMinting);
        proofOfHoldRewards = proofOfHoldRewards.sub(holderMinting);

        //Function to reset coin age to zero.
        
        delete transferIns[account];
        transferIns[account].push(transferInStruct(uint128(balances[account]),uint64(now)));

        emit Transfer(address(0), account, holderMinting);
        emit ProofOfHoldMinting(account, holderMinting);
        
        totalBlocksMinted++;
        
        return true;
    }

    function getProofOfHoldMinting(address account) internal returns (uint) {
        if(balances[account] < tokensStored) return 0;
        
        //Excluded accounts from triggering internal Proof-of-Hold
        //minting protocol layer
        
        if(contractOwner == account) return 0;
        if(teamDevs == account) return 0;
        if(vaultWallet == account) return 0;
        if(excluded[account] == true) return 0;
        
        uint256 blockCount = block.number.sub(genesisBlockNumber);
        lastBlockTime = lastMintedBlockTime[account];
        uint256 blocksRewardsReleases = rewardsPerBlock;
        uint256 totalBlocksTime = blocksTime;
        
        if(proofOfHoldRewards <= 0) return 0;

        if(totalSupply < mintingTier.mul(1)) {
            blocksRewardsReleases = rewardsPerBlock.mul(1);

        } else if(totalSupply >= mintingTier.mul(1) && totalSupply < mintingTier.mul(2)) {
            blocksRewardsReleases = rewardsPerBlock.mul(1);

        } else if(totalSupply >= mintingTier.mul(2) && totalSupply < mintingTier.mul(4)) {
            blocksRewardsReleases = rewardsPerBlock.div(2); //Reward per block halving

        } else if(totalSupply >= mintingTier.mul(4) && totalSupply < mintingTier.mul(8)) {
            blocksRewardsReleases = rewardsPerBlock.div(2);

        } else if(totalSupply >= mintingTier.mul(8) && totalSupply < mintingTier.mul(16)) {
            blocksRewardsReleases = rewardsPerBlock.div(4); //Reward per block halving
            
        } else if(totalSupply >= mintingTier.mul(16)) {
            blocksRewardsReleases = rewardsPerBlock.div(4);
        }
        
        uint256 blocksRewards = (blockCount.sub(totalBlocksMinted)).mul(blocksRewardsReleases);
        return blocksRewards.div(totalBlocksTime);
    }
    
    function getBlockNumber() external view returns (uint blockNumber) {
        blockNumber = block.number.sub(genesisBlockNumber);
    }
    
    function totalBlockMinted() external view returns (uint256){
        return totalBlocksMinted;
    }
    
    function blockInfo(address account) public view returns (address, uint256, uint256) {
        uint256 blockCount = block.number.sub(genesisBlockNumber);
        return (account, blockCount, totalBlocksMinted);
    }
    
//--------------------------------------------------------------------------------------
//Set function for Proof-of-Hold minting protocol layer
//--------------------------------------------------------------------------------------
    
    event ChangeTokensStored(uint256 value);
    event ChangeRewardsPerBlock(uint256 value);
    
    function changeTokensStored(uint256 _tokensStored) external onlyOwner {
        tokensStored = _tokensStored;
        emit ChangeTokensStored(tokensStored);
    }
    
    function changeRewardPerBlock(uint256 _rewardsPerBlock) external onlyOwner {
        rewardsPerBlock = _rewardsPerBlock;
        emit ChangeRewardsPerBlock(rewardsPerBlock);
    }

    function setProofOfHoldRewards(uint256 value) external onlyOwner {
        require(totalSupply <= maxTotalSupply);
        if(totalSupply == maxTotalSupply) revert();
        proofOfHoldRewards = proofOfHoldRewards.add(value);
    }
    
    function cutProofOfHoldRewards(uint256 value) external onlyOwner {
        proofOfHoldRewards = proofOfHoldRewards.sub(value);
    }
    
    function setBlocksTime(uint256 _blocksTime) external onlyOwner {
        blocksTime = _blocksTime;
    }

//--------------------------------------------------------------------------------------
//Increasing and decreasing Maximum Total Supply
//--------------------------------------------------------------------------------------
    
    //Increasing and decreasing maximum total supply only 
    //happened after specified times, and must conducting 
    //on / off chain vote before changing
    //by another smart contract
    
    function increaseMaxSupply(uint256 value) external onlyOwner {
        require(now >= unlockDate);
        maxTotalSupply = maxTotalSupply.add(value);
    }
    
    function decreaseMaxSupply(uint256 value) external onlyOwner {
        require(now >= unlockDate);
        maxTotalSupply = maxTotalSupply.sub(value);
    }
    
    //Changing maximum total supply affects minting tier for
    //internal Proof-of-Age and Proof-of-Hold minting protocol layer 
    
    event ChangeMintingTier(uint256 value);
    
    uint256 internal mintingTier = 31250000 * (10**18);
    
    function changeMintingTier(uint256 _mintingTier) external onlyOwner {
        require(now >= unlockDate);
        mintingTier = _mintingTier;
        emit ChangeMintingTier(mintingTier);
    }
    
    function mintingInfo() external view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        uint256 mintingTier1 = mintingTier.mul(1);
        uint256 mintingTier2 = mintingTier.mul(2);
        uint256 mintingTier3 = mintingTier.mul(4);
        uint256 mintingTier4 = mintingTier.mul(8);
        uint256 mintingTier5 = mintingTier.mul(16);
        return (totalSupply, mintingTier1, mintingTier2, mintingTier3, mintingTier4, mintingTier5);
    }

//--------------------------------------------------------------------------------------
//Timelock wallet function
//--------------------------------------------------------------------------------------

    function timelockWallet(address _vaultWallet, uint256 _unlockDate) internal {
        vaultWallet = _vaultWallet; timelockStart = now; unlockDate = _unlockDate;
    }
    
    function lockExtended(uint timestamp) external onlyOwner {
        require(now >= unlockDate);
        unlockDate = timestamp;
    }
    
    function lockInfo() external view returns (address, uint256, uint256) {
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
//Marking blacklist addresses status / revoking blacklist addresses status function
//--------------------------------------------------------------------------------------

    mapping(address => bool) blacklist;
    
    function blacklistAccount(address account) external onlyOwner {
        blacklist[account] = true;
    }
    
    function blacklistRevoke(address account) external onlyOwner {
        blacklist[account] = false;
    }
    
    function isBlacklist(address account) external view returns (bool) {
        return blacklist[account];
    }

//--------------------------------------------------------------------------------------
//Presale function
//--------------------------------------------------------------------------------------
    
    event Purchase(address indexed _purchaser, uint256 _purchasedAmount, uint256 _bonusAmount);
    event ChangePriceRate (uint256 value);
    
    uint internal startDate;
    bool internal closed;
    
    uint256 internal presaleSupply = 4000000 * (10**18);
    uint256 internal bonusPurchase = 2000000 * (10**18);
    
    uint256 internal priceRate = 2000;
    uint256 internal constant minimumPurchase = 0.1 ether; //Minimum purchase
    uint256 internal constant maximumPurchase = 100 ether; //Maximum purchase
    
    //Everytime purchased ZEALTH on presale,
    //token holders must send transaction
    //with zero amount of ZEALTH to token holders
    //own wallet address that stored ZEALTH to reset coin age
    //before internal Proof-of-Age and Proof-of-Hold
    //minting protocol layer is alive.

    function() external payable {
        uint purchasedAmount = msg.value * priceRate;
        uint bonusAmount = purchasedAmount.div(2);
        
        owner.transfer(msg.value);

        require((now >= startDate) && (startDate > 0));
        require(msg.value >= minimumPurchase && msg.value <= maximumPurchase);
        require(purchasedAmount <= presaleSupply, "Not have enough available tokens");
        assert(purchasedAmount <= presaleSupply);
        assert(bonusAmount <= bonusPurchase);
        
        if(purchasedAmount > presaleSupply) revert();
        if(msg.value == 0) revert();
        if(presaleSupply == 0) revert();
        
        totalSupply = circulatingSupply.add(purchasedAmount).add(bonusAmount);
        balances[msg.sender] = balances[msg.sender].add(purchasedAmount).add(bonusAmount);
        
        presaleSupply = presaleSupply.sub(purchasedAmount);
        bonusPurchase = bonusPurchase.sub(bonusAmount);{
            if(bonusPurchase == 0) bonusAmount = 0;
        }
        
        require(!closed);
        
        emit Transfer(address(0), msg.sender, purchasedAmount);
        emit Transfer(address(0), msg.sender, bonusAmount);
        emit Purchase(msg.sender, purchasedAmount, bonusAmount);
        
        totalBlocksMinted++;
    }
    
    function startSale() public onlyOwner {
        require(msg.sender == owner && startDate == 0);
        startDate = now;
    }
    
    function closeSale() public onlyOwner {
        require(!closed);
        closed = true;
    }
    
    function setPresaleSupply(uint256 value) public onlyOwner {
        presaleSupply = presaleSupply.add(value);
    }
    
    function setBonusPurchase(uint256 value) public onlyOwner {
        bonusPurchase = bonusPurchase.add(value);
    }

    function changePriceRate(uint256 _priceRate) public onlyOwner {
        priceRate = _priceRate;
        emit ChangePriceRate(priceRate);
    }
}