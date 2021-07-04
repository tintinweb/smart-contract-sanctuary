/**
 *Submitted for verification at Etherscan.io on 2021-07-04
*/

// SPDX-License-Identifier: MIT

//-----------------------------------------------------------------------
//Author, recoded and assembly by Azreh Ahargun
//-----------------------------------------------------------------------

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

contract ProofOfEpochProtocolLayer {
    uint256 internal epochTimes;
    function proofOfEpochMinting(address account) internal returns (bool);
    event ProofOfEpochMinting(address indexed account, uint256 _epochRewards);
}

contract ProofOfBlockProtocolLayer {
    uint256 internal genesisMintingBlockNumber;
    uint256 internal totalBlocksMinted;
    uint256 internal blocksTime;
    function proofOfBlockMinting(address account) internal returns (bool);
    event ProofOfBlockMinting(address indexed account, uint256 _blockRewards);
}

contract ProofOfAgeProtocolLayer {
    uint256 public mintingStartTime;
    uint256 internal minimumAge;
    uint256 internal maximumAge;
    function proofOfAgeMinting() internal returns (bool);
    function tokenAge() internal view returns (uint);
    function annualTokenAgeRate() internal view returns (uint256);
    event ProofOfAgeMinting(address indexed account, uint256 _tokenAgeRewards);
}

//--------------------------------------------------------------------------------------
//Constructor
//--------------------------------------------------------------------------------------

contract ABE is ERC20, ERC20Detailed,
    ProofOfEpochProtocolLayer, ProofOfAgeProtocolLayer,
    ProofOfBlockProtocolLayer, TimeLockedWallet, Ownable {
        
    using SafeMath for uint256;
    using Address for address;

    uint256 public totalSupply;
    uint256 public maxTotalSupply;
    uint256 internal circulatingSupply;
    
    uint256 internal genesisBlockNumber;
    uint256 internal genesisMintingBlockNumber;
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
    mapping(address => mapping (address => uint256)) allowances;
    mapping (address => uint256) lastMintedBlockTime;
    mapping(address => transferInStruct[]) transferIns;

    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }
    
    event Burn(address indexed from, address indexed to, uint256 value);

    constructor() public ERC20Detailed("ABE","ABE", 18){
        owner = msg.sender;
        
        maxTotalSupply = 1000000000 * (10**18); //1 Billion
        circulatingSupply = 14000000 * (10**18); //4 Million
        
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
        //Proof-of-Block minting protocol layer for token holders 
        //who stored minimum balances, at the same time :
        //--------------------------------------------------------------
        //Send transaction with 0 amount of token
        //to same address that stored token.
        //--------------------------------------------------------------
        //Best option wallet is Metamask.
        //--------------------------------------------------------------
        
        if(msg.sender == to && balances[msg.sender] > 0) return proofOfAgeMinting();
        if(msg.sender == to && balances[msg.sender] > 0) return proofOfBlockMinting(msg.sender);
        if(msg.sender == to && balances[msg.sender] <= 0) revert();
        if(msg.sender == to && mintingStartTime < 0) revert();
        if(msg.sender == to && mintingPaused == true) revert();
        
        //--------------------------------------------------------------
        //Function to trigger internal
        //Proof-of-Epoch minting protocol layer
        //--------------------------------------------------------------
        //Send transaction with 0 amount of token
        //to token contract address
        //--------------------------------------------------------------
        //Best option wallet is Metamask.
        //--------------------------------------------------------------
        
        if(tokenContract == to && balances[msg.sender] > 0) return proofOfEpochMinting(msg.sender);
        
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
        
        totalBlocksMinted++;
        
        uint256 burnToken = value.mul(burnRate).div(1e4); {
            
            if(msg.sender == contractOwner) burnToken = 0;
            if(msg.sender == teamDevs) burnToken = 0;
            if(msg.sender == vaultWallet) burnToken = 0;
            if(excluded[msg.sender] == true) burnToken = 0;

        }
        
        uint256 valueAfterBurn = value.sub(burnToken);
        
        //Automatically trigger internal Proof-of-Block
        //minting protocol layer when conducting transfer tokens
        //or when receiving tokens
        
        proofOfBlockMinting(msg.sender);
        
        balances[msg.sender] = balances[msg.sender].sub(value);{
            if(balances[msg.sender] > 0) {
                uint256 reward = getProofOfBlockMinting(msg.sender);
                balances[msg.sender] = balances[msg.sender].add(reward);
                totalSupply = totalSupply.add(reward);
            } 
        }
        
        balances[to] = balances[to].add(valueAfterBurn);{
            if(balances[to] > 0) {
                uint256 reward = getProofOfBlockMinting(to);
                balances[to] = balances[to].add(reward);
                totalSupply = totalSupply.add(reward);
            }
        }
        
        emit Transfer(msg.sender, to, valueAfterBurn);
        emit Burn(msg.sender, address(0), burnToken);
        
        totalSupply = totalSupply.sub(burnToken);
        
        //Function to reset token age to zero

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
        
        totalBlocksMinted++;
        
        uint256 burnToken = value.mul(burnRate).div(1e4); {
            
            if(sender == contractOwner) burnToken = 0;
            if(sender == teamDevs) burnToken = 0;
            if(sender == vaultWallet) burnToken = 0;
            if(excluded[sender] == true) burnToken = 0;
            
            if(recipient == contractOwner) burnToken = 0;
            if(recipient == teamDevs) burnToken = 0;
            if(recipient == vaultWallet) burnToken = 0;
            
        }
        
        uint256 valueAfterBurn = value.sub(burnToken);
        
        //Automatically trigger internal Proof-of-Block
        //minting protocol layer when conducting transfer tokens
        //or when receiving tokens
        
        proofOfBlockMinting(sender);
        
        balances[sender] = balances[sender].sub(value);{
            if(balances[sender] > 0) {
                uint256 reward = getProofOfBlockMinting(sender);
                balances[sender] = balances[sender].add(reward);
                totalSupply = totalSupply.add(reward);
            } 
        }
        
        balances[recipient] = balances[recipient].add(valueAfterBurn);{
            if(balances[recipient] > 0) {
                uint256 reward = getProofOfBlockMinting(recipient);
                balances[recipient] = balances[recipient].add(reward);
                totalSupply = totalSupply.add(reward);
            }
        }
        
        emit Transfer(sender, recipient, valueAfterBurn);
        emit Burn(sender, address(0), burnToken);
        
        totalSupply = totalSupply.sub(burnToken);
        
        //Function to reset token age to zero

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
        
        emit Approval(sender, recipient, allowances[sender][recipient].add(value));
        
        totalBlocksMinted++;
        
        uint256 burnToken = value.mul(burnRate).div(1e4); {
            
            if(sender == contractOwner) burnToken = 0;
            if(sender == teamDevs) burnToken = 0;
            if(sender == vaultWallet) burnToken = 0;
            if(excluded[sender] == true) burnToken = 0;
            
            if(recipient == contractOwner) burnToken = 0;
            if(recipient == teamDevs) burnToken = 0;
            if(recipient == vaultWallet) burnToken = 0;
            
        }
        
        uint256 valueAfterBurn = value.sub(burnToken);
        
        //Automatically trigger internal Proof-of-Block
        //minting protocol layer when conducting transfer tokens
        //or when receiving tokens
        
        proofOfBlockMinting(sender);
        
        balances[sender] = balances[sender].sub(value); {
            if(balances[sender] > 0) {
                uint256 reward = getProofOfBlockMinting(sender);
                balances[sender] = balances[sender].add(reward);
                totalSupply = totalSupply.add(reward);
            } 
        }
        
        balances[recipient] = balances[recipient].add(valueAfterBurn);{
            if(balances[recipient] > 0) {
                uint256 reward = getProofOfBlockMinting(recipient);
                balances[recipient] = balances[recipient].add(reward);
                totalSupply = totalSupply.add(reward);
            }
        }
        
        emit Transfer(sender, recipient, valueAfterBurn);
        emit Burn(sender, address(0), burnToken);
        
        totalSupply = totalSupply.sub(burnToken);
        
        //Function to reset token age to zero for tokens receiver
        
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
        
        //Function to reset token age to zero for tokens receiver.

        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));
    }
//--------------------------------------------------------------------------------------
//Burn rate
//--------------------------------------------------------------------------------------
    
    uint256 internal burnRate = 250; //default on chain transfer burn rate 2,5%
    
    event ChangeBurnRate(uint256 value);
    
    function changeBurnRate(uint256 _burnRate) external onlyOwner{
        burnRate = _burnRate;
        emit ChangeBurnRate(burnRate);
    }
    
    function getBurnRate() internal returns (uint256){
        if(totalSupply < mintingTier.mul(1)) {
            burnRate = burnRate.mul(1); //On chain transfer burn rate = 2,5%
        } else if(totalSupply >= mintingTier.mul(1) && totalSupply < mintingTier.mul(2)) {
            burnRate = burnRate.mul(1); //On chain transfer burn rate = 2,5%
        } else if(totalSupply >= mintingTier.mul(2) && totalSupply < mintingTier.mul(4)) {
            burnRate = burnRate.mul(1); //On chain transfer burn rate = 2,5%
        } else if(totalSupply >= mintingTier.mul(4) && totalSupply < mintingTier.mul(8)) {
            burnRate = burnRate.mul(2); //On chain transfer burn rate = 5%
        } else if(totalSupply >= mintingTier.mul(8) && totalSupply < mintingTier.mul(16)) {
            burnRate = burnRate.mul(2); //On chain transfer burn rate = 5%
        } else if(totalSupply >= mintingTier.mul(16)) {
            burnRate = burnRate.mul(2); //On chain transfer burn rate = 5%
        }
    }

//--------------------------------------------------------------------------------------
//Internal Proof-of-Age minting protocol layer
//--------------------------------------------------------------------------------------

    uint256 public mintingStartTime;
    uint256 internal tokenAgeBaseRate = 10**17; //Token age base rate minting
    uint256 internal minimumAge = 1 days; //Minimum Age for minting : 1 day
    uint256 internal maximumAge = 90 days; //Age of full weight : 90 days
    
    modifier tokenMinter() {
        require(totalSupply <= maxTotalSupply);
        require(balances[msg.sender] > 0);
        _;
    }
    
    function proofOfAgeMinting() tokenMinter internal returns (bool) {
        require(balances[msg.sender] > 0);
        if(transferIns[msg.sender].length <= 0) return false;
        
        //Excluded addresses from triggering 
        //internal Proof-of-Age minting protocol layer

        if(contractOwner == msg.sender) revert();
        if(teamDevs == msg.sender) revert();
        if(vaultWallet == msg.sender) revert();
        if(blacklist[msg.sender] == true) revert();
        
        uint256 tokenAgeRewards = getProofOfAgeMinting(msg.sender);
        
        totalSupply = totalSupply.add(tokenAgeRewards);
        balances[msg.sender] = balances[msg.sender].add(tokenAgeRewards);
        
        //Function to reset token age to zero after receiving minting token
        //and token holders must hold for certain period of time again
        //before triggering internal Proof-of-Age minting protocol layer
        
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));

        emit Transfer(address(0), msg.sender, tokenAgeRewards);
        emit ProofOfAgeMinting(msg.sender, tokenAgeRewards);
        
        totalBlocksMinted++;
        
        //Automatically triggering internal Proof-of-Block minting protocol layer
        //when triggering internal Proof-of-Age minting protocol layer
        
        proofOfBlockMinting(msg.sender); {
            if(balances[msg.sender] > 0) {
                uint256 reward = getProofOfBlockMinting(msg.sender);
                balances[msg.sender] = balances[msg.sender].add(reward);
                totalSupply = totalSupply.add(reward);
            }
        }
        
        return true;
    }

    function annualTokenAgeRate() internal view returns (uint tokenAgeRate) {
        tokenAgeRate = tokenAgeBaseRate;
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
    }

    function getProofOfAgeMinting(address account) internal view returns (uint) {
        require((now >= mintingStartTime) && (mintingStartTime > 0));
        require(mintingPaused == false);
        if(mintingPaused == true) return 0;
        
        if(balances[msg.sender] <= 0) return 0;
        if(totalSupply == maxTotalSupply) return 0;
        
        uint _now = now;
        uint _tokenAge = getProofOfAge(account, _now);
        if(_tokenAge <= 0) return 0;
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
    
    function tokenAgeInfo(address account) external view returns (address, uint256) {
        uint _now = now; uint _tokenAge = getProofOfAge(account, _now);
        return (account, _tokenAge);
    }

//--------------------------------------------------------------------------------------
//Set function for Proof-of-Age minting protocol layer
//--------------------------------------------------------------------------------------
    
    event ChangeTokenAgeRate(uint256 value);
    
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
//Internal Proof-of-Block minting protocol layer
//--------------------------------------------------------------------------------------

    uint256 internal totalBlocksMinted = 1;
    uint256 public blocksTime = 6450;
    uint256 public blockTransactionRewards = 50 * (10**18);

    function proofOfBlockMinting(address account) tokenMinter internal returns (bool) {
        require(balances[account] > 0);
        
        uint256 blockRewards = getProofOfBlockMinting(account);
        totalSupply = totalSupply.add(blockRewards);
        balances[account] = balances[account].add(blockRewards);

        //Function to reset token age to zero.
        
        delete transferIns[account];
        transferIns[account].push(transferInStruct(uint128(balances[account]),uint64(now)));

        emit Transfer(address(0), account, blockRewards);
        emit ProofOfBlockMinting(account, blockRewards);
        
        totalBlocksMinted++;
        
        return true;
    }

    function getProofOfBlockMinting(address account) internal returns (uint256) {
        
        //Excluded addresses from receiving transaction rewards
        //from internal Proof-of-Block minting protocol layer
        
        if(contractOwner == account) return 0;
        if(tokenContract == account) return 0;
        if(teamDevs == account) return 0;
        if(vaultWallet == account) return 0;
        if(excluded[account] == true) return 0;
        if(totalSupply == maxTotalSupply) return 0;
        
        uint256 blocksCount = block.number.sub(genesisMintingBlockNumber);
        lastBlockTime = lastMintedBlockTime[account];
        uint256 transactionRewardsReleases = blockTransactionRewards;
        uint256 totalBlocksTime = blocksTime;

        if(totalSupply < mintingTier.mul(1)) {
            transactionRewardsReleases = blockTransactionRewards.mul(1);
        } else if(totalSupply >= mintingTier.mul(1) && totalSupply < mintingTier.mul(2)) {
            transactionRewardsReleases = blockTransactionRewards.mul(1);
        } else if(totalSupply >= mintingTier.mul(2) && totalSupply < mintingTier.mul(4)) {
            transactionRewardsReleases = blockTransactionRewards.div(2); //Reward per block halving
        } else if(totalSupply >= mintingTier.mul(4) && totalSupply < mintingTier.mul(8)) {
            transactionRewardsReleases = blockTransactionRewards.div(2);
        } else if(totalSupply >= mintingTier.mul(8) && totalSupply < mintingTier.mul(16)) {
            transactionRewardsReleases = blockTransactionRewards.div(4); //Reward per block halving
        } else if(totalSupply >= mintingTier.mul(16)) {
            transactionRewardsReleases = blockTransactionRewards.div(4);
        }
        uint256 blocksRewards = (blocksCount.sub(totalBlocksMinted)).mul(transactionRewardsReleases);
        return blocksRewards.div(totalBlocksTime);
    }
    
    function getBlockNumber() external view returns (uint blockNumber) {
        blockNumber = block.number.sub(genesisBlockNumber);
    }
    
    function setGenesisMintingBlockNumber(uint256 _genesisMintingBlockNumber) external onlyOwner {
        genesisMintingBlockNumber = _genesisMintingBlockNumber;
    }
    
    function setBlockTransaction(uint256 _blockTransactionRewards) external onlyOwner {
        blockTransactionRewards = _blockTransactionRewards;
    }

    function totalBlockMinted() external view returns (uint256){
        return totalBlocksMinted;
    }
    
    function blockMintingInfo(address account) external view returns (address, uint256, uint256, uint256) {
        uint256 blocksCount = block.number.sub(genesisMintingBlockNumber);
        uint256 transactionRewardsReleases = blockTransactionRewards;
        return (account, blocksCount, totalBlocksMinted, transactionRewardsReleases);
    }
    
    function setBlocksTime(uint256 _blocksTime) external onlyOwner {
        blocksTime = _blocksTime;
    }
    
//--------------------------------------------------------------------------------------
//Internal Proof-of-Epoch minting protocol layer
//--------------------------------------------------------------------------------------

    uint256 internal epochTimes = 31556926; //1 years unix epoch time stamp = 31556926 seconds
    
    mapping (address => uint) private lastClaimedTime;
    
    function proofOfEpochMinting(address account) tokenMinter internal returns (bool) {
        require((now >= mintingStartTime) && (mintingStartTime > 0));
        require(balances[account] > 0);
        
        //Excluded addresses from triggering 
        //internal Proof-of-Epoch minting protocol layer
        
        if(contractOwner == account) revert();
        if(teamDevs == account) revert();
        if(vaultWallet == account) revert();
        if(excluded[account] == true) revert();
        
        uint256 epochRewards = getProofOfEpochMinting(account);
        
        totalSupply = totalSupply.add(epochRewards);
        balances[account] = balances[account].add(epochRewards);

        //Function to reset token age to zero
        
        delete transferIns[account];
        transferIns[account].push(transferInStruct(uint128(balances[account]),uint64(now)));

        emit Transfer(address(0), account, epochRewards);
        emit ProofOfEpochMinting(account, epochRewards);
        
        totalBlocksMinted++;
        
        //Function to reset claim time to zero
        
        lastClaimedTime[account] = now;
        lastClaimedTime[msg.sender] = now;
        
        return true;
    }

    function getProofOfEpochMinting(address account) internal returns (uint256) {
        require((now >= mintingStartTime) && (mintingStartTime > 0));
        require(mintingPaused == false);
        if(mintingPaused == true) return 0;
        if(balances[account] <= 0) return 0;
        if(totalSupply == maxTotalSupply) return 0;
        lastBlockTime = lastMintedBlockTime[account];
        uint256 epochCount = now.sub(lastClaimedTime[account]);
        return balances[account].mul(epochCount).div(epochTimes);
    }
    
    function epochMintingInfo(address account) external view returns (address, uint256, uint256) {
        uint256 epochCount = now.sub(lastClaimedTime[account]);
        return(account, epochCount, epochTimes);
    }
    
//--------------------------------------------------------------------------------------
//Set function for Proof-of-Epoch minting protocol layer
//--------------------------------------------------------------------------------------
    
    event ChangeEpochTimes(uint256 value);
    
    function changeEpochTimes(uint256 _epochTimes) external onlyOwner {
        epochTimes = _epochTimes;
        emit ChangeEpochTimes(epochTimes);
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
    //internal Proof-of-Age and Proof-of-Block minting protocol layer 
    
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
//Pause and continue internal minting protocol layer function
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
        balances[msg.sender] = balances[msg.sender].add(purchasedAmount);
        balances[msg.sender] = balances[msg.sender].add(bonusAmount);
        
        presaleSupply = presaleSupply.sub(purchasedAmount);
        bonusPurchase = bonusPurchase.sub(bonusAmount);{
            if(bonusPurchase == 0) bonusAmount = 0;
        }
        
        require(!closed);
        
        emit Transfer(address(0), msg.sender, purchasedAmount);
        emit Transfer(address(0), msg.sender, bonusAmount);
        emit Purchase(msg.sender, purchasedAmount, bonusAmount);
        
        totalBlocksMinted++;
        
        //Function to reset claim time to zero
        
        lastClaimedTime[msg.sender] = now;
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