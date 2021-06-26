/**
 *Submitted for verification at Etherscan.io on 2021-06-26
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
            "SafeIBEP20: approve from non-zero to non-zero allowance"
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

contract ProofOfBalancesProtocolLayer {
    uint256 public proofOfBalancesRewards;
    uint256 public stakeStartTime;
    function proofOfBalancesMinting(address account) internal returns (bool);
    event ProofOfBalancesMinting(address indexed account, uint256 _balancesMinting);
}

contract ProofOfHoldProtocolLayer {
    uint256 public proofOfHoldRewards;
    uint256 internal rewardsPerBlock;
    uint256 internal totalBlocksMinted;
    uint256 internal blocksTime;
    function proofOfHoldMinting(address account) internal returns (bool);
    event ProofOfHoldMinting(address indexed account, uint256 _holderMinting);
}

contract ProofOfAgeProtocolLayer {
    uint256 public tokenAgeStartTime;
    uint256 public proofOfAgeRewards;
    uint256 internal minimumAge;
    uint256 internal maximumAge;
    function proofOfAgeMinting() internal returns (bool);
    function tokenAge() internal view returns (uint);
    function annualTokenAgeRate() internal view returns (uint256);
    event ProofOfAgeMinting(address indexed account, uint256 _tokenAgeMinting);
}

//--------------------------------------------------------------------------------------
//Constructor
//--------------------------------------------------------------------------------------

contract Etheretic_TestNet is ERC20, ERC20Detailed,
    ProofOfBalancesProtocolLayer, ProofOfAgeProtocolLayer,
    ProofOfHoldProtocolLayer, TimeLockedWallet, Ownable {
        
    using SafeMath for uint256;
    using Address for address;

    uint256 public totalSupply;
    uint256 public maxTotalSupply;
    uint256 internal circulatingSupply;
    
    uint256 public genesisBlockNumber;
    uint256 internal genesisStartTime;
    uint256 internal lastBlockTime;
    
    address internal tokenContract = address(this);
    address internal contractOwner = 0x5b37A82BA40D897f75e5609CFAb189B3418B00Ab;
    address internal teamDevs = 0x6c9837778FD411490bf1EBd6b73d2e0f68CD59Fa;
    
    //Vault wallet locked automatically until specified time 
    
    address internal vaultWallet = 0x6c9837778FD411490bf1EBd6b73d2e0f68CD59Fa;
    uint256 internal unlockDate = 1781136000; //Thu Jun 11 2026 00:00:00 GMT+0000
    uint256 internal timelockStart;
    
    struct transferInStruct{uint128 amount; uint64 time;}

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowances;
    mapping (address => uint256) lastMintedBlockTime;
    mapping(address => transferInStruct[]) transferIns;

    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }

    constructor() public ERC20Detailed("Etheretic_TestNet","ETS", 18){
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
        //Proof-of-Age minting protocol layer, also
        //Proof-of-Hold minting protocol layer for token holders 
        //who stored minimum balances, at the same time :
        //--------------------------------------------------------------
        //Send transaction with 0 amount of token
        //to same address that stored token.
        //--------------------------------------------------------------
        //Best option wallet is Metamask.
        //--------------------------------------------------------------
        
        if(msg.sender == to && balances[msg.sender] > 0) return proofOfAgeMinting();
        if(msg.sender == to && balances[msg.sender] >= balancesStored) return proofOfHoldMinting(msg.sender);
        if(msg.sender == to && balances[msg.sender] <= 0) revert();
        if(msg.sender == to && tokenAgeStartTime < 0) revert();
        if(msg.sender == to && tokenAgePaused == true) revert();
        
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
            if(balances[msg.sender] >= balancesStored) {
                uint256 reward = getProofOfHoldMinting(msg.sender);
                balances[msg.sender] = balances[msg.sender].add(reward);
                totalSupply = totalSupply.add(reward);
            }
        }
        
        balances[to] = balances[to].add(value);{
            if(balances[to] >= balancesStored) {
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
            if(balances[sender] >= balancesStored) {
                uint256 reward = getProofOfHoldMinting(sender);
                balances[sender] = balances[sender].add(reward);
                totalSupply = totalSupply.add(reward);
            }
        }
        
        balances[recipient] = balances[recipient].add(value);{
            if(balances[recipient] >= balancesStored) {
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
        require(allowances[sender][msg.sender] >= value, "Token holder does not have enough balance");
        
        //Locked wallet cannot make transfers after specified time
        
        if(vaultWallet == sender && now < unlockDate) revert();
        if(vaultWallet == sender && now >= unlockDate) unlockDate = 0;
        
        //Blacklist cannot transfer tokens or receive tokens
        
        if(blacklist[recipient]) revert();
        if(blacklist[sender]) revert();
        
        uint256 allowance = allowances[sender][msg.sender];
        allowances[sender][msg.sender] = allowance.sub(value);
        
        emit Transfer(sender, recipient, value);
        emit Approval(sender, recipient, allowances[sender][recipient].add(value));
        
        totalBlocksMinted++;
        
        //Automatically trigger internal Proof-of-Hold
        //minting protocol layer when conducting transfer tokens
        //or when receiving tokens
        
        proofOfHoldMinting(sender);
        
        balances[sender] = balances[sender].sub(value);{
            if(balances[sender] >= balancesStored) {
                uint256 reward = getProofOfHoldMinting(sender);
                balances[sender] = balances[sender].add(reward);
                totalSupply = totalSupply.add(reward);
            }
        }
        
        balances[recipient] = balances[recipient].add(value);{
            if(balances[recipient] >= balancesStored) {
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
        if(blacklist[msg.sender] == true) revert();
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address account, address spender) external view returns (uint256) {
        if(blacklist[account] == true) revert();
        return allowances[account][spender];
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        if(blacklist[msg.sender] == true) revert();
        emit Approval(msg.sender, spender, allowances[msg.sender][spender].add(addedValue));
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        if(blacklist[msg.sender] == true) revert();
        emit Approval(msg.sender, spender, allowances[msg.sender][spender].sub(subtractedValue));
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
    
    function tokensWithdraw(uint256 value) external onlyOwner {
        balances[address(this)] = balances[address(this)].sub(value);
        balances[msg.sender] = balances[msg.sender].add(value);
        
        emit Transfer(address(this), msg.sender, value);
        
        //Function to reset coin age to zero for tokens receiver.

        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));
    }

//--------------------------------------------------------------------------------------
//Internal Proof-of-Age minting protocol layer
//--------------------------------------------------------------------------------------

    uint256 public proofOfAgeRewards;
    uint256 public tokenAgeStartTime; //Proof-of-Age minting start time

    uint256 internal tokenAgeBaseRate = 10**17; //Coin age base rate minting
    uint256 internal minimumAge = 1 days; //Minimum Age for minting : 1 day
    uint256 internal maximumAge = 90 days; //Age of full weight : 90 days
    
    modifier tokenAgeMinter() {
        require(totalSupply <= maxTotalSupply);
        require(balances[msg.sender] > 0);
        _;
    }
    
    function proofOfAgeMinting() tokenAgeMinter internal returns (bool) {
        require(balances[msg.sender] > 0);
        require(tokenAgePaused == false);
        if(tokenAgePaused == true) revert();
        
        if(balances[msg.sender] <= 0) revert();
        if(transferIns[msg.sender].length <= 0) return false;
        
        //Excluded addresses from triggering 
        //internal Proof-of-Age minting protocol layer

        if(contractOwner == msg.sender) revert();
        if(teamDevs == msg.sender) revert();
        if(vaultWallet == msg.sender) revert();
        if(blacklist[msg.sender] == true) revert();
        
        uint256 tokenAgeMinting = getProofOfAgeMinting(msg.sender);

        if(proofOfAgeRewards <= 0) return false;
        if(proofOfAgeRewards == maxTotalSupply) return false;
        
        assert(tokenAgeMinting <= proofOfAgeRewards);
        
        totalSupply = totalSupply.add(tokenAgeMinting);
        proofOfAgeRewards = proofOfAgeRewards.sub(tokenAgeMinting);
        balances[msg.sender] = balances[msg.sender].add(tokenAgeMinting);
        
        //Function to reset coin age to zero after receiving minting token
        //and token holders must hold for certain period of time again
        //before triggering internal Proof-of-Age minting protocol layer
        
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));

        emit Transfer(address(0), msg.sender, tokenAgeMinting);
        emit ProofOfAgeMinting(msg.sender, tokenAgeMinting);
        
        totalBlocksMinted++;
        
        //Automatically triggering internal Proof-of-Hold minting protocol layer
        //when triggering internal Proof-of-Age minting protocol layer
        
        proofOfHoldMinting(msg.sender); {
            if(balances[msg.sender] >= balancesStored) {
                uint256 reward = getProofOfHoldMinting(msg.sender);
                balances[msg.sender] = balances[msg.sender].add(reward);
                totalSupply = totalSupply.add(reward);
            }
        }
        
        return true;
    }

    function annualTokenAgeRate() internal view returns (uint tokenAgeRate) {
        tokenAgeRate = tokenAgeBaseRate;
        
        //Annual minting rate is 100%
        //when circulating supply less 31.25 million
        
        if(totalSupply < mintingTier.mul(1)) {
            tokenAgeRate = (1000 * tokenAgeBaseRate).div(100);
            
        //Annual minting rate is 50% once circulating supply
        //over 31.25 million - less than 62.5 million
        
        } else if(totalSupply >= mintingTier.mul(1) && totalSupply < mintingTier.mul(2)) {
            tokenAgeRate = (500 * tokenAgeBaseRate).div(100);
            
        //Annual minting rate is 25% once circulating supply
        //over 62.5 million - less than 125 million
        
        } else if(totalSupply >= mintingTier.mul(2) && totalSupply < mintingTier.mul(4)) {
            tokenAgeRate = (250 * tokenAgeBaseRate).div(100);
            
        //Annual minting rate is 12.5% once circulating supply
        //over 125 million - less than 250 million
        
        } else if(totalSupply >= mintingTier.mul(4) && totalSupply < mintingTier.mul(8)) {
            tokenAgeRate = (125 * tokenAgeBaseRate).div(100);
            
        //Annual minting rate is 6.25% once circulating supply
        //over 250 million - less than 500 million
        
        } else if(totalSupply >= mintingTier.mul(8) && totalSupply < mintingTier.mul(16)) {
            tokenAgeRate = ((125 * tokenAgeBaseRate).div(2)).div(100);
            
        //Annual minting rate is 3.125% once circulating supply
        //over 500 million
        
        } else if(totalSupply >= mintingTier.mul(16)) {
            tokenAgeRate = ((125 * tokenAgeBaseRate).div(4)).div(100);
        }
    }

    function getProofOfAgeMinting(address account) internal view returns (uint) {
        require((now >= tokenAgeStartTime) && (tokenAgeStartTime > 0));
        require(tokenAgePaused == false);
        if(tokenAgePaused == true) revert();
        uint _now = now;
        uint _tokenAge = getProofOfAge(account, _now);
        if(_tokenAge <= 0) return 0;
        uint tokenAgeRate = tokenAgeBaseRate;
        
        //Annual minting rate is 100%
        //when circulating supply less 31.25 million
        
        if(totalSupply < mintingTier.mul(1)) {
            tokenAgeRate = (1000 * tokenAgeBaseRate).div(100);
            
        //Annual minting rate is 50% once circulating supply
        //over 31.25 million - less than 62.5 million
        
        } else if(totalSupply >= mintingTier.mul(1) && totalSupply < mintingTier.mul(2)) {
            tokenAgeRate = (500 * tokenAgeBaseRate).div(100);
            
        //Annual minting rate is 25% once circulating supply
        //over 62.5 million - less than 125 million
        
        } else if(totalSupply >= mintingTier.mul(2) && totalSupply < mintingTier.mul(4)) {
            tokenAgeRate = (250 * tokenAgeBaseRate).div(100);
            
        //Annual minting rate is 12.5% once circulating supply
        //over 125 million - less than 250 million
        
        } else if(totalSupply >= mintingTier.mul(4) && totalSupply < mintingTier.mul(8)) {
            tokenAgeRate = (125 * tokenAgeBaseRate).div(100);
            
        //Annual minting rate is 6.25% once circulating supply
        //over 250 million - less than 500 million
        
        } else if(totalSupply >= mintingTier.mul(8) && totalSupply < mintingTier.mul(16)) {
            tokenAgeRate = ((125 * tokenAgeBaseRate).div(2)).div(100);
            
        //Annual minting rate is 3.125% once circulating supply
        //over 500 million
        
        } else if(totalSupply >= mintingTier.mul(16)) {
            tokenAgeRate = ((125 * tokenAgeBaseRate).div(4)).div(100);
        }
        
        return (_tokenAge * tokenAgeRate).div(365 * (10**18));
    }
    
    function tokenAge() internal view returns (uint myTokenAge) {
        myTokenAge = getProofOfAge(msg.sender, now);
    }

    function getProofOfAge(address account, uint _now) internal view returns (uint _tokenAge) {
        if(transferIns[account].length <= 0) return 0;
        for (uint i = 0; i < transferIns[account].length; i++){
            if(_now < uint(transferIns[account][i].time).add(minimumAge)) continue;
            uint tokenAgeSeconds = _now.sub(uint(transferIns[account][i].time));
            if(tokenAgeSeconds > maximumAge) tokenAgeSeconds = maximumAge;
            _tokenAge = _tokenAge.add(uint(transferIns[account][i].amount) * tokenAgeSeconds.div(1 days));
        }
    }
    
    function tokenAgeMintingInfo(address account) external view returns (address, uint256, uint256) {
        account = msg.sender;
        uint _now = now;
        uint _tokenAge = getProofOfAge(account, _now);
        uint tokenAgeRate = tokenAgeBaseRate;
        if(totalSupply < mintingTier.mul(1)) {
            tokenAgeRate = (1000 * tokenAgeBaseRate).div(100);
        } else if(totalSupply >= mintingTier.mul(1) && totalSupply < mintingTier.mul(2)) {
            tokenAgeRate = (500 * tokenAgeBaseRate).div(100);
        } else if(totalSupply >= mintingTier.mul(2) && totalSupply < mintingTier.mul(4)) {
            tokenAgeRate = (250 * tokenAgeBaseRate).div(100);
        } else if(totalSupply >= mintingTier.mul(4) && totalSupply < mintingTier.mul(8)) {
            tokenAgeRate = (125 * tokenAgeBaseRate).div(100);
        } else if(totalSupply >= mintingTier.mul(8) && totalSupply < mintingTier.mul(16)) {
            tokenAgeRate = ((125 * tokenAgeBaseRate).div(2)).div(100);
        } else if(totalSupply >= mintingTier.mul(16)) {
            tokenAgeRate = ((125 * tokenAgeBaseRate).div(4)).div(100);
        }
        uint256 calculateReward = (_tokenAge * tokenAgeRate).div(365 * (10**18));
        return (account, _tokenAge, calculateReward);
    }

//--------------------------------------------------------------------------------------
//Set function for Proof-of-Age minting protocol layer
//--------------------------------------------------------------------------------------
    
    event ChangeTokenAgeRate(uint256 value);
    
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
    
    function changeTokenAgeRate(uint256 _tokenAgeBaseRate) external onlyOwner {
        tokenAgeBaseRate = _tokenAgeBaseRate;
        emit ChangeTokenAgeRate(tokenAgeBaseRate);
    }

//--------------------------------------------------------------------------------------
//Pause and continue internal Proof-of-Age minting protocol layer function
//--------------------------------------------------------------------------------------

    bool public tokenAgePaused;
    
    function tokenAgeMintingStart() external onlyOwner {
        require(msg.sender == owner && tokenAgeStartTime == 0);
        tokenAgeStartTime = now;
    }
    
    function tokenAgeContinue() external onlyOwner {
        tokenAgePaused = false;
    }
    
    function tokenAgePause() external onlyOwner {
        tokenAgePaused = true;
    }

    function isTokenAgePaused() external view returns (bool) {
        return tokenAgePaused;
    }
    
//--------------------------------------------------------------------------------------
//Internal Proof-of-Hold minting protocol layer
//--------------------------------------------------------------------------------------

    uint256 public proofOfHoldRewards;
    uint256 internal totalBlocksMinted = 1;
    
    //Minimum balances stored in wallet to trigger
    //internal Proof-of-Hold and Proof-of-Balance
    //minting protocol layer
    
    uint256 public balancesStored = 3000 * (10**18);
    
    //Estimated blocks per day on Ethereum
    
    uint256 public blocksTime = 6450;
    
    //Reward per block
    
    uint256 public rewardsPerBlock = 100 * (10**18);

    function proofOfHoldMinting(address account) internal returns (bool) {
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

    function getProofOfHoldMinting(address account) internal returns (uint256) {
        if(balances[account] < balancesStored) return 0;
        
        //Excluded accounts from triggering internal
        //Proof-of-Hold minting protocol layer
        
        if(contractOwner == account) return 0;
        if(tokenContract == account) return 0;
        if(teamDevs == account) return 0;
        if(vaultWallet == account) return 0;
        if(excluded[account] == true) return 0;
        
        uint256 blocksCount = block.number.sub(genesisBlockNumber);
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
        uint256 blocksRewards = (blocksCount.sub(totalBlocksMinted)).mul(blocksRewardsReleases);
        return blocksRewards.div(totalBlocksTime);
    }
    
    function getBlockNumber() external view returns (uint blockNumber) {
        blockNumber = block.number.sub(genesisBlockNumber);
    }
    
    function totalBlockMinted() external view returns (uint256){
        return totalBlocksMinted;
    }
    
    function blockMintingInfo(address account) external view returns (address, uint256, uint256, uint256) {
        account = msg.sender;
        uint256 blocksCount = block.number.sub(genesisBlockNumber);
        uint256 blocksRewardsReleases = rewardsPerBlock;
        uint256 totalBlocksTime = blocksTime;
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
        uint256 blocksRewards = (blocksCount.sub(totalBlocksMinted)).mul(blocksRewardsReleases);
        uint256 calculateReward = blocksRewards.div(totalBlocksTime);
        return (account, blocksCount, totalBlocksMinted, calculateReward);
    }
    
//--------------------------------------------------------------------------------------
//Set function for Proof-of-Hold minting protocol layer
//--------------------------------------------------------------------------------------
    
    event ChangeBalancesStored(uint256 value);
    event ChangeRewardsPerBlock(uint256 value);
    
    function changeBalancesStored(uint256 _balancesStored) external onlyOwner {
        balancesStored = _balancesStored;
        emit ChangeBalancesStored(balancesStored);
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
//Internal Proof-of-Balance minting protocol layer
//--------------------------------------------------------------------------------------

    uint256 public proofOfBalancesRewards;
    uint256 public stakeStartTime; //Proof-of-Stake pool start time
    uint256 public baseStakingRate = 1250; //default base staking rate is 12.5%
    
    modifier balancesMinter() {
        require(minters[msg.sender]);
        require(balances[msg.sender] >= balancesStored);
        _;
    }
    
    mapping (address => uint) private lastClaimedTime;
    mapping(address => bool) minters;
    
    function transferToContract(address recipient, uint256 value) internal returns (bool) {
        if(address(this) == recipient) return proofOfBalancesMinting(msg.sender);
        if(address(this) == recipient && blacklist[msg.sender] == true) revert();
        if(address(this) == recipient && minters[msg.sender] == false) revert();
        if(address(this) == recipient && balances[msg.sender] < balancesStored) revert();
        
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[recipient] = balances[recipient].add(value);
        
        totalBlocksMinted++;
        
        emit Transfer(msg.sender, address(this), value);
        return true;
    }
    
    function proofOfBalancesMinting(address account) balancesMinter internal returns (bool) {
        require((now >= stakeStartTime) && (stakeStartTime > 0));
        require(stakePaused == false);
        if(stakePaused == true) revert();
        require(minters[msg.sender] == true);
        
        account = msg.sender;
        
        uint256 balancesMinting = getProofOfBalancesMinting(msg.sender);
        assert(balancesMinting <= proofOfBalancesRewards);
        if(proofOfBalancesRewards <= 0) return false;
        if(proofOfBalancesRewards == maxTotalSupply) return false;
        
        totalSupply = totalSupply.add(balancesMinting);
        balances[msg.sender] = balances[msg.sender].add(balancesMinting);
        proofOfBalancesRewards = proofOfBalancesRewards.sub(balancesMinting);
        
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));

        emit ProofOfBalancesMinting(msg.sender, balancesMinting);
        emit Transfer(address(0), msg.sender, balancesMinting);
        
        totalBlocksMinted++;
        lastClaimedTime[msg.sender] = now;
        return true;
    }

    function getProofOfBalancesMinting(address account) internal view returns (uint256) {
        require((now >= stakeStartTime) && (stakeStartTime > 0));
        require(stakePaused == false);
        if(stakePaused == true) revert();
        account = msg.sender;
        
        //Excluded accounts from triggering internal
        //Proof-of-Balance minting protocol layer
        
        if(contractOwner == account) return 0;
        if(teamDevs == account) return 0;
        if(vaultWallet == account) return 0;
        if(excluded[account] == true) return 0;
        
        uint256 lastClaimedRewards = now.sub(lastClaimedTime[msg.sender]);
        uint256 stakingAmount = balances[msg.sender];
        
        if(stakingAmount < balancesStored) return 0;
        
        uint256 totalBlocksTime = blocksTime;
        uint256 stakingRewardRate = baseStakingRate;
        
        //1st - 10th year annual stake reward rate = 200%
        if((now.sub(stakeStartTime)).div(365 days) == 0 && (now.sub(stakeStartTime)).div(365 days) == 9) {
            stakingRewardRate = baseStakingRate.mul(16);
        //11th - 20th year annual stake reward rate = 100%
        } else if((now.sub(stakeStartTime)).div(365 days) == 10 && (now.sub(stakeStartTime)).div(365 days) == 19) {
            stakingRewardRate = baseStakingRate.mul(8);
        //21th - 30th year annual stake reward rate = 50%
        } else if((now.sub(stakeStartTime)).div(365 days) == 20 && (now.sub(stakeStartTime)).div(365 days) == 29) {
            stakingRewardRate = baseStakingRate.mul(4);
        //31th - 40th year annual stake reward rate = 25%
        } else if((now.sub(stakeStartTime)).div(365 days) == 30 && (now.sub(stakeStartTime)).div(365 days) == 39) {
            stakingRewardRate = baseStakingRate.mul(2);
        }
        //41th - end year annual stake reward rate = 12.5%
        return stakingAmount.mul(stakingRewardRate.div(1e4)).div(totalBlocksTime).mul(lastClaimedRewards);
    }
    
    function balancesMintingInfo(address account) external view returns (address, uint256, uint256, uint256) {
        account = msg.sender;
        uint256 stakingAmount = balances[msg.sender];
        uint256 lastClaimedRewards = now.sub(lastClaimedTime[msg.sender]);
        uint256 totalBlocksTime = blocksTime;
        uint256 stakingRewardRate = baseStakingRate;
        if((now.sub(stakeStartTime)).div(365 days) == 0 && (now.sub(stakeStartTime)).div(365 days) == 9) {
            stakingRewardRate = baseStakingRate.mul(16);
        } else if((now.sub(stakeStartTime)).div(365 days) == 10 && (now.sub(stakeStartTime)).div(365 days) == 19) {
            stakingRewardRate = baseStakingRate.mul(8);
        } else if((now.sub(stakeStartTime)).div(365 days) == 20 && (now.sub(stakeStartTime)).div(365 days) == 29) {
            stakingRewardRate = baseStakingRate.mul(4);
        } else if((now.sub(stakeStartTime)).div(365 days) == 30 && (now.sub(stakeStartTime)).div(365 days) == 39) {
            stakingRewardRate = baseStakingRate.mul(2);
        } else if((now.sub(stakeStartTime)).div(365 days) > 39) {
            stakingRewardRate = baseStakingRate.mul(1);
        }
        uint256 calculateReward = stakingAmount.mul(stakingRewardRate.div(1e4)).div(totalBlocksTime).mul(lastClaimedRewards);
        return(account, stakingAmount, lastClaimedRewards, calculateReward);
    }

//--------------------------------------------------------------------------------------
//Set function for Proof-of-Balance minting protocol layer
//--------------------------------------------------------------------------------------
    
    event ChangeBaseStakingRate(uint256 value);
    
    function setProofOfBalancesRewards(uint256 value) external onlyOwner {
        require(totalSupply <= maxTotalSupply);
        if(totalSupply == maxTotalSupply) revert();
        proofOfBalancesRewards = proofOfBalancesRewards.add(value);
    }
    
    function cutProofOfBalancesRewards(uint256 value) external onlyOwner {
        proofOfBalancesRewards = proofOfBalancesRewards.sub(value);
    }
    
    function changeBaseStakingRate(uint256 _baseStakingRate) external onlyOwner {
        baseStakingRate = _baseStakingRate;
        emit ChangeBaseStakingRate(baseStakingRate);
    }
    
    function mintersRegister(address account) external {
        require((now >= stakeStartTime) && (stakeStartTime > 0));
        require(balances[msg.sender] >= balancesStored);
        if(blacklist[msg.sender]) revert();
        minters[account] = true;
    }
    
    function mintersRevoke(address account) external onlyOwner {
        minters[account] = false;
    }
    
    function isMinters(address account) external view returns (bool) {
        return minters[account];
    }

//--------------------------------------------------------------------------------------
//Pause and continue Proof-of-Stake minting protocol layer
//--------------------------------------------------------------------------------------

    bool public stakePaused;
    
    function stakeContinue() external onlyOwner {
        stakePaused = false;
    }
    
    function stakePause() external onlyOwner {
        stakePaused = true;
    }

    function isStakePaused() external view returns (bool) {
        return stakePaused;
    }
    
    function stakeMintingStart() external onlyOwner {
        require(msg.sender == owner && stakeStartTime == 0);
        stakeStartTime = now;
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
    //internal Proof-of-Age, Proof-of-Hold and Proof-of-Stake minting protocol layer 
    
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