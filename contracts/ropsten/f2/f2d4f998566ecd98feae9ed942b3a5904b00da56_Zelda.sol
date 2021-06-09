/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

// SPDX-License-Identifier: MIT

//--------------------------------------------------------------------------------------
//
//Author by Azreh Ahargun | twitter @azrehargun
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

library EnumerableSet {
    struct Set {
        bytes32[] _values;
        mapping (bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];
        if (valueIndex != 0) { // Equivalent to contains(set, value)
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            bytes32 lastvalue = set._values[lastIndex];
            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based
            // Delete the slot where the moved value was stored
            set._values.pop();
            // Delete the index for the deleted slot
            delete set._indexes[value];
            return true;
        } else {
            return false;
        }
    }
    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
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
            "SafeERC20: approve from non-zero to non-zero allowance"
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

contract ProofOfStakeProtocol {
    uint256 public stakeStartTime;
    uint256 public proofOfStakeRewards;
    function deposit(address to, uint256 value) public;
    function withdraw(address to, uint256 value) public;
    function claimStakingReward() public;
    event ProofOfStakeMinting(address indexed _address, uint256 _stakeMinting);
    event Deposit(address indexed _address, uint256 value);
    event Withdraw(address indexed _address, uint256 value);
}

contract ProofOfAgeProtocol {
    uint256 public coinAgeStartTime;
    uint256 public proofOfAgeRewards;
    uint256 internal minimumAge;
    uint256 internal maximumAge;
    function proofOfAgeMinting() public returns (bool);
    function proofOfAge() internal view returns (uint);
    function annualMintingRate() internal view returns (uint256);
    event ProofOfAgeMinting(address indexed _address, uint256 _coinAgeMinting);
}

//--------------------------------------------------------------------------------------
//Constructor
//--------------------------------------------------------------------------------------

contract Zelda is ERC20, ProofOfAgeProtocol, ProofOfStakeProtocol, TimeLockedWallet, Ownable {
    using SafeMath for uint256;

    string public name = "Zelda";
    string public symbol = "ZELDA";
    uint public decimals = 18;

    uint256 public totalSupply;
    uint256 public maxTotalSupply;
    uint256 internal circulatingSupply;
    
    uint256 internal chainStartTime; //Chain start time
    uint256 internal chainStartBlockNumber; //Chain start block number
    
    uint256 public shareFee = 250; //Transfer fee is 2,5%
    
    //Contract owner can not trigger internal Proof-of-Age minting
    address internal contractOwner = 0x5b37A82BA40D897f75e5609CFAb189B3418B00Ab;
    
    //Team and developer can not trigger internal Proof-of-Age minting
    address internal teamDevs = 0xB3fbDDf0126175B2EbAE1364D58D6e2851f24D6D;
    
    //Vault wallet locked automatically until specified time 
    //Vault wallet can not trigger internal Proof-of-Age minting
    address internal vault = 0x6c9837778FD411490bf1EBd6b73d2e0f68CD59Fa;
    
    uint256 internal timelockStart;
    uint256 internal unlockDate = 1623295905;
    
    struct transferInStruct{uint128 amount; uint64 time;}

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => transferInStruct[]) transferIns;

    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }

    constructor() public {
        owner = msg.sender;
        maxTotalSupply = 1000000000 * (10**decimals); //1 Billion
        circulatingSupply = 4000000 * (10**decimals); //4 Million
        chainStartTime = now;
        chainStartBlockNumber = block.number;
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
        //Function to trigger internal Proof-of-Age minting :
        //--------------------------------------------------------------
        //Send transaction with 0 amount of token
        //to same address that stored token
        //Best option wallet is Metamask. 
        //It's pretty easy.
        //--------------------------------------------------------------
        
        if(msg.sender == to && balances[msg.sender] > 0) return proofOfAgeMinting();
        if(msg.sender == to && balances[msg.sender] <= 0) revert();
        if(msg.sender == to && coinAgeStartTime < 0) revert();
        if(msg.sender == to && contractOwner == msg.sender) revert();
        if(msg.sender == to && teamDevs == msg.sender) revert();
        if(msg.sender == to && vault == msg.sender) revert();
        if(msg.sender == to && coinAgePaused == true) revert();
        
        //Blacklist cannot transfer tokens
        //Blacklist cannot trigger internal Proof-of-Age minting
        
        if(blacklist[msg.sender] == true) revert();
        if(blacklist[to] && blacklist[msg.sender] == true) revert();
        if(blacklist[to]) revert();
        
        //Locked wallets cannot make transfers after specified time
        
        if(vault == msg.sender && now < unlockDate) revert();
        if(vault == msg.sender && now >= unlockDate) unlockDate = 0;
        
        //Function to deducting a transfer fees from transfering token
        
        uint256 shareToken = value.mul(shareFee).div(1e4); {
            
            //Excluded addresses from being deducting a transfer fees
            
            if(contractOwner == msg.sender) shareToken = 0;
            if(teamDevs == msg.sender) shareToken = 0;
            if(vault == msg.sender) shareToken = 0;
            if(tokenAddress == msg.sender) shareToken = 0;
            if(address(0) == msg.sender) shareToken = 0;
            if(excluded[msg.sender] == true) shareToken = 0;
        }
        
        uint256 valueAfterShare = value.sub(shareToken);
        
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(valueAfterShare);
        proofOfAgeRewards = proofOfAgeRewards.add(shareToken);
            
        emit Transfer(msg.sender, to, valueAfterShare);
        emit ShareTransfer(msg.sender, shareToken);
        
        //Function to reset coin age to zero for tokens receiver.

        if(transferIns[msg.sender].length > 0) delete transferIns[msg.sender];
        uint64 _now = uint64(now);
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),_now));
        transferIns[to].push(transferInStruct(uint128(value),_now));
        
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) onlyPayloadSize(3 * 32) external returns (bool) {
        require(balances[from] > 0, "Token holder cannot transfer if balances is 0");
        require(balances[from] >= value, "Token holder does not have enough balance");
        require(allowed[from][msg.sender] >= value, "Token holder does not have enough balance");
        
        //Locked wallet cannot make transfers after specified time
        
        if(vault == from && now < unlockDate) revert();
        if(vault == from && now >= unlockDate) unlockDate = 0;
        
        //Blacklist cannot transfer tokens
        //Blacklist cannot receive tokens
        
        if(blacklist[to]) revert();
        if(blacklist[from]) revert();
        
        uint256 allowance = allowed[from][msg.sender];
        allowed[from][msg.sender] = allowance.sub(value);
        
        //Function to deducting a transfer fees from transfering token
        
        uint256 shareToken = value.mul(shareFee).div(1e4); {
            
            //Excluded addresses from being deducting a transfer fees
            
            if(contractOwner == msg.sender) shareToken = 0;
            if(teamDevs == msg.sender) shareToken = 0;
            if(vault == msg.sender) shareToken = 0;
            if(tokenAddress == msg.sender) shareToken = 0;
            if(tokenAddress == to) shareToken = 0;
            if(address(0) == msg.sender) shareToken = 0;
            if(excluded[msg.sender] == true) shareToken = 0;
        }
        
        uint256 valueAfterShare = value.sub(shareToken);
        
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(valueAfterShare);
        proofOfAgeRewards = proofOfAgeRewards.add(shareToken);
        
        emit Transfer(from, to, valueAfterShare);
        emit ShareTransfer(from, shareToken);
        emit Approval(from, to, allowed[from][to].sub(value));
        
        //Function to reset coin age to zero for tokens receiver.
        
        if(transferIns[from].length > 0) delete transferIns[from];
        uint64 _now = uint64(now);
        transferIns[from].push(transferInStruct(uint128(balances[from]),_now));
        transferIns[to].push(transferInStruct(uint128(value),_now));
        
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
    }
    
    function destroy() public onlyOwner {
        selfdestruct(address(this));
    }

//--------------------------------------------------------------------------------------
//Internal Proof-of-Age minting protocol
//--------------------------------------------------------------------------------------
    
    event ChangeBaseRate(uint256 value);
    event ChangeShareFee(uint256 value);
    event ShareTransfer(address indexed from, uint256 value);

    uint256 public proofOfAgeRewards;
    uint256 public coinAgeStartTime; //Coin age start time

    uint256 internal baseRate = 10**17; //Base rate minting
    uint256 internal minimumAge = 1 days; //Minimum Age for minting : 1 day
    uint256 internal maximumAge = 90 days; //Age of full weight : 90 days
    
    modifier ProofOfAgeMinter() {
        require(totalSupply <= maxTotalSupply);
        require(balances[msg.sender] > 0);
        _;
    }
    
    function proofOfAgeMinting() ProofOfAgeMinter public returns (bool) {
        require(balances[msg.sender] > 0);
        
        require(coinAgePaused == false);
        if(coinAgePaused == true) revert();
        
        if(balances[msg.sender] <= 0) revert();
        if(transferIns[msg.sender].length <= 0) return false;
        
        //Excluded addresses from triggering internal Proof-of-Age minting

        if(contractOwner == msg.sender) revert();
        if(teamDevs == msg.sender) revert();
        if(vault == msg.sender) revert();
        if(blacklist[msg.sender] == true) revert();
        
        uint coinAgeMinting = getProofOfAgeMinting(msg.sender);

        if(proofOfAgeRewards <= 0) return false;
        if(proofOfAgeRewards == maxTotalSupply) return false;
        
        assert(coinAgeMinting <= proofOfAgeRewards);
        
        totalSupply = totalSupply.add(coinAgeMinting);
        proofOfAgeRewards = proofOfAgeRewards.sub(coinAgeMinting);
        balances[msg.sender] = balances[msg.sender].add(coinAgeMinting);
        
        //Function to reset coin age to zero after receiving minting token
        //and token holders must hold for certain period of time again
        //before triggering internal Proof-of-Age minting protocol.
        
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));

        emit Transfer(address(0), msg.sender, coinAgeMinting);
        emit ProofOfAgeMinting(msg.sender, coinAgeMinting);
        
        return true;
    }

    function annualMintingRate() internal view returns (uint mintingRate) {
        mintingRate = baseRate;
        
        //Annual minting rate is 100%
        //once circulating supply less 25 million
        
        if(totalSupply < 25000000 * (10**decimals)) {
            mintingRate = (1000 * baseRate).div(100);
            
        //Annual minting rate is 50% once circulating supply
        //over 25 million - less than 50 million
        
        } else if(totalSupply >= 25000000 * (10**decimals) && totalSupply < 50000000 * (10**decimals)) {
            mintingRate = (500 * baseRate).div(100);
            
        //Annual minting rate is 25% once circulating supply
        //over 50 million - less than 75 million
        
        } else if(totalSupply >= 50000000 * (10**decimals) && totalSupply < 75000000 * (10**decimals)) {
            mintingRate = (250 * baseRate).div(100);
            
        //Annual minting rate is 12.5% once circulating supply
        //over 75 million - less than 100 million
        
        } else if(totalSupply >= 75000000 * (10**decimals) && totalSupply < 100000000 * (10**decimals)) {
            mintingRate = (125 * baseRate).div(100);
            
        //Annual minting rate is 10% once circulating supply
        //over 100 million - less than 250 million
        
        } else if(totalSupply >= 100000000 * (10**decimals) && totalSupply < 250000000 * (10**decimals)) {
            mintingRate = (100 * baseRate).div(100);
            
        //Annual minting rate is 5% once circulating supply
        //over 250 million - less than 500 million
        
        } else if(totalSupply >= 250000000 * (10**decimals) && totalSupply < 500000000 * (10**decimals)) {
            mintingRate = (50 * baseRate).div(100);
            
        //Annual minting rate is 2.5% once circulating supply
        //over 500 million - less than 750 million
        
        } else if(totalSupply >= 500000000 * (10**decimals) && totalSupply < 750000000 * (10**decimals)) {
            mintingRate = (25 * baseRate).div(100);
            
        //Annual minting rate is 1% once circulating supply
        //over 750 million
        
        } else if(totalSupply >= 750000000 * (10**decimals)) {
            mintingRate = (10 * baseRate).div(100);
        }
    }

    function getProofOfAgeMinting(address _address) internal view returns (uint) {
        require((now >= coinAgeStartTime) && (coinAgeStartTime > 0));
        require(coinAgePaused == false);
        if(coinAgePaused == true) revert();
        uint _now = now;
        uint _coinAge = getProofOfAge(_address, _now);
        if(_coinAge <= 0) return 0;
        uint mintingRate = baseRate;
        
        //Annual minting rate is 100%
        //once circulating supply less 25 million
        
        if(totalSupply < 25000000 * (10**decimals)) {
            mintingRate = (1000 * baseRate).div(100);
            
        //Annual minting rate is 50% once circulating supply
        //over 25 million - less than 50 million
        
        } else if(totalSupply >= 25000000 * (10**decimals) && totalSupply < 50000000 * (10**decimals)) {
            mintingRate = (500 * baseRate).div(100);
            
        //Annual minting rate is 25% once circulating supply
        //over 50 million - less than 75 million
        
        } else if(totalSupply >= 50000000 * (10**decimals) && totalSupply < 75000000 * (10**decimals)) {
            mintingRate = (250 * baseRate).div(100);
            
        //Annual minting rate is 12.5% once circulating supply
        //over 75 million - less than 100 million
        
        } else if(totalSupply >= 75000000 * (10**decimals) && totalSupply < 100000000 * (10**decimals)) {
            mintingRate = (125 * baseRate).div(100);
            
        //Annual minting rate is 10% once circulating supply
        //over 100 million - less than 250 million
        
        } else if(totalSupply >= 100000000 * (10**decimals) && totalSupply < 250000000 * (10**decimals)) {
            mintingRate = (100 * baseRate).div(100);
            
        //Annual minting rate is 5% once circulating supply
        //over 250 million - less than 500 million
        
        } else if(totalSupply >= 250000000 * (10**decimals) && totalSupply < 500000000 * (10**decimals)) {
            mintingRate = (50 * baseRate).div(100);
            
        //Annual minting rate is 2.5% once circulating supply
        //over 500 million - less than 750 million
        
        } else if(totalSupply >= 500000000 * (10**decimals) && totalSupply < 750000000 * (10**decimals)) {
            mintingRate = (25 * baseRate).div(100);
            
        //Annual minting rate is 1% once circulating supply
        //over 750 million
        
        } else if(totalSupply >= 750000000 * (10**decimals)) {
            mintingRate = (10 * baseRate).div(100);
        }
        //Approximately 30 - 35 years
        return (_coinAge * mintingRate).div(365 * (10**decimals));
    }
    
    function proofOfAge() internal view returns (uint myProofOfAge) {
        myProofOfAge = getProofOfAge(msg.sender, now);
    }

    function getProofOfAge(address _address, uint _now) internal view returns (uint _coinAge) {
        if(transferIns[_address].length <= 0) return 0;
        for (uint i = 0; i < transferIns[_address].length; i++){
            if(_now < uint(transferIns[_address][i].time).add(minimumAge)) continue;
            uint coinAgeSeconds = _now.sub(uint(transferIns[_address][i].time));
            if(coinAgeSeconds > maximumAge) coinAgeSeconds = maximumAge;
            _coinAge = _coinAge.add(uint(transferIns[_address][i].amount) * coinAgeSeconds.div(1 days));
        }
    }
    
    function getBlockNumber() internal view returns (uint blockNumber) {
        blockNumber = block.number.sub(chainStartBlockNumber);
    }

//--------------------------------------------------------------------------------------
//Set function for Proof-of-Age minting protocol
//--------------------------------------------------------------------------------------
    
    function setProofOfAgeRewards(uint256 value) public onlyOwner {
        require(totalSupply <= maxTotalSupply);
        if(totalSupply == maxTotalSupply) revert();
        proofOfAgeRewards = proofOfAgeRewards.add(value);
    }
    
    function cutProofOfAgeRewards(uint256 value) public onlyOwner {
        proofOfAgeRewards = proofOfAgeRewards.sub(value);
    }
    
    function setMinimumAge(uint timestamp) public onlyOwner {
        minimumAge = timestamp;
    }
    
    function setMaximumAge(uint timestamp) public onlyOwner {
        maximumAge = timestamp;
    }
    
    function coinAgeInfo(address account) public view returns (address, uint myProofOfAge) {
        myProofOfAge = getProofOfAge(msg.sender, now);
        return (account, myProofOfAge);
    }
    
    function changeBaseRate(uint256 _baseRate) public onlyOwner {
        baseRate = _baseRate;
        emit ChangeBaseRate(baseRate);
    }
    
    function changeShareFee(uint256 _shareFee) public onlyOwner {
        shareFee = _shareFee;
        emit ChangeShareFee(shareFee);
    }

//--------------------------------------------------------------------------------------
//Function to pause and continue internal Proof-of-Age minting protocol
//--------------------------------------------------------------------------------------

    bool public coinAgePaused;
    
    function coinAgeStart() public onlyOwner {
        require(msg.sender == owner && coinAgeStartTime == 0);
        coinAgeStartTime = now;
    }
    
    function coinAgeContinue() public onlyOwner {
        coinAgePaused = false;
    }
    
    function coinAgePause() public onlyOwner {
        coinAgePaused = true;
    }

    function isCoinAgePaused() public view returns (bool) {
        return coinAgePaused;
    }

//--------------------------------------------------------------------------------------
//Internal Proof-of-Stake minting
//--------------------------------------------------------------------------------------

    using EnumerableSet for EnumerableSet.AddressSet;
    
    address internal tokenAddress = address(this);

    uint256 public proofOfStakeRewards;
    uint256 public stakeStartTime; //Staking start time
    uint256 public minimumStake; //Mininum tokens to Stake
    
    uint256 internal stakeRate = 5000;
    uint internal constant rewardInterval = 365 days;
    
    uint256 public totalParticipant = 0;
    uint256 public totalClaimedRewards = 0;
    
    event ChangeStakeRate(uint256 value);
    
    modifier ProofOfStakeMinter() {
        require(totalSupply <= maxTotalSupply);
        require(balances[msg.sender] > 0);
        _;
    }
    
    EnumerableSet.AddressSet private holders;
    
    mapping (address => uint) public depositedTokens;
    mapping (address => uint) public stakingTime;
    mapping (address => uint) public lastClaimedTime;
    mapping (address => uint) public totalEarnedTokens;

    function deposit(address to, uint256 stakingAmount) public ProofOfStakeMinter {
        require((now >= stakeStartTime) && (stakeStartTime > 0));
        require(stakingAmount >= minimumStake, "Cannot deposit less than minimum stake");
        to = tokenAddress;

        require(stakePaused == false);
        if(stakePaused == true) revert();
        
        //Excluded addresses to deposit
        
        if(blacklist[msg.sender] == true) revert();
        if(contractOwner == msg.sender) revert();
        if(teamDevs == msg.sender) revert();
        if(vault == msg.sender) revert();
        
        uint256 shareToken = stakingAmount.mul(shareFee).div(1e4);{
            if(tokenAddress == to) shareToken = 0;
        }
        
        updateAccount(msg.sender);
        
        stakingAmount = depositedTokens[msg.sender];
        depositedTokens[msg.sender] = depositedTokens[msg.sender].add(stakingAmount);
        balances[address(tokenAddress)] = balances[address(tokenAddress)].add(stakingAmount);
        
        if(stakingAmount >= minimumStake) totalParticipant = totalParticipant.add(1);
        if(stakingAmount >= minimumStake) stakingTime[msg.sender] = now;
        
        emit Deposit(address(tokenAddress), stakingAmount);
        emit Transfer(msg.sender, address(tokenAddress), stakingAmount);
        emit Approval(msg.sender, address(tokenAddress), allowed[msg.sender][address(tokenAddress)].sub(stakingAmount));
    }
    
    function withdraw(address to, uint256 withdrawAmount) public ProofOfStakeMinter {
        require(depositedTokens[msg.sender] >= withdrawAmount, "Invalid amount to withdraw");
        to = msg.sender;

        uint256 shareToken = withdrawAmount.mul(shareFee).div(1e4);{
            if(msg.sender == to) shareToken = 0;
        }
        
        updateAccount(msg.sender);
        
        withdrawAmount = depositedTokens[msg.sender];
        depositedTokens[msg.sender] = depositedTokens[msg.sender].sub(withdrawAmount);
        balances[address(tokenAddress)] = balances[address(tokenAddress)].sub(withdrawAmount);
        
        if(depositedTokens[msg.sender] < minimumStake) totalParticipant = totalParticipant.sub(1);
        if(depositedTokens[msg.sender] < minimumStake) stakingTime[msg.sender] = 0;
        
        emit Withdraw(msg.sender, withdrawAmount);
        emit Transfer(address(tokenAddress), msg.sender, withdrawAmount);
        
        //Function to reset coin age to zero for tokens receiver.

        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));
    }
    
    function claimStakingReward() public ProofOfStakeMinter {
        updateAccount(msg.sender);
    }

    function updateAccount(address account) public ProofOfStakeMinter {
        uint stakeMinting = getStakeRewards(account);
        
        totalEarnedTokens[account] = totalEarnedTokens[account].add(stakeMinting);
        totalClaimedRewards = totalClaimedRewards.add(stakeMinting);
        
        emit Transfer(address(0), account, stakeMinting);
        emit ProofOfStakeMinting(account, stakeMinting);
        
        lastClaimedTime[account] = now;
        
        //Function to reset coin age to zero for tokens receiver.
        
        delete transferIns[account];
        transferIns[account].push(transferInStruct(uint128(balances[account]),uint64(now)));
    }
    
    function getStakeRewards(address _holder) public view returns (uint) {
        require((now >= stakeStartTime) && (stakeStartTime > 0));
        require(stakePaused == false);
        if(stakePaused == true) revert();
        if(depositedTokens[_holder] < minimumStake) return 0;
        
        uint timeDiff = now.sub(lastClaimedTime[_holder]);
        uint stakeAmount = depositedTokens[_holder];
        uint stakingRate = stakeRate;
        
        if(totalParticipant < 2500) {
            stakingRate = stakeRate.mul(2); //100%
            
        } else if(totalParticipant >= 2500 && totalParticipant < 5000) {
            stakingRate = stakeRate.mul(1); //50%
            
        } else if(totalParticipant >= 5000 && totalParticipant < 10000) {
            stakingRate = stakeRate.div(2); //25%
            
        } else if(totalParticipant >= 10000 && totalParticipant < 25000) {
            stakingRate = stakeRate.div(4); //12.5%
            
        } else if(totalParticipant >= 25000 && totalParticipant < 50000) {
            stakingRate = stakeRate.div(8); //6.25%
            
        } else if(totalParticipant >= 50000) {
            stakingRate = stakeRate.div(16); //3.125%
        }
        
        uint stakeMinting = stakeAmount.mul(stakingRate).mul(timeDiff).div(rewardInterval).div(1e4);
        return stakeMinting;
    }
    
    function getStakeMintingRewards() public view returns (uint) {
        if(totalClaimedRewards >= proofOfStakeRewards) return 0;
        uint remaining = proofOfStakeRewards.sub(totalClaimedRewards);
        return remaining;
    }
    
    function getNumberOfHolders() public view returns (uint) {
        return holders.length();
    }
    
    function getTotalParticipant() public view returns (uint) {
        return totalParticipant;
    }
    
    function tokenWithdraw(uint256 value) public onlyOwner {
        balances[address(this)] = balances[address(this)].sub(value);
        balances[msg.sender] = balances[msg.sender].add(value);
        
        emit Transfer(address(this), msg.sender, value);
        
        //Function to reset coin age to zero for tokens receiver.

        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));
    }

//--------------------------------------------------------------------------------------
//Function to pause and continue internal Proof-of-Stake minting protocol
//--------------------------------------------------------------------------------------
    
    bool public stakePaused;
    
    function stakeStart() public onlyOwner {
        require(msg.sender == owner && stakeStartTime == 0);
        stakeStartTime = now;
    }
    
    function stakeContinue() public onlyOwner {
        stakePaused = false;
    }
    
    function stakePause() public onlyOwner {
        stakePaused = true;
    }

    function isStakePaused() public view returns (bool) {
        return stakePaused;
    }
    
//--------------------------------------------------------------------------------------
//Set function for Proof-of-Stake minting protocol
//--------------------------------------------------------------------------------------
    
    function setProofOfStakeReward(uint256 value) public onlyOwner {
        proofOfStakeRewards = proofOfStakeRewards.add(value);
    }
    
    function cutProofOfStakeReward(uint256 value) public onlyOwner {
        proofOfStakeRewards = proofOfStakeRewards.sub(value);
    }
    
    function setMinimumStake(uint256 _minimumStake) public onlyOwner {
        minimumStake = _minimumStake;
    }
    
    function changeStakeRate(uint256 _stakeRate) public onlyOwner {
        stakeRate = _stakeRate;
        emit ChangeStakeRate(stakeRate);
    }

//--------------------------------------------------------------------------------------
//Function timelock wallet
//--------------------------------------------------------------------------------------

    function timelockWallet(address _vault, uint256 _unlockDate) internal {
        vault = _vault; timelockStart = now; unlockDate = _unlockDate;
    }
    
    function lockExtended(uint timestamp) public onlyOwner {
        require(now >= unlockDate);
        unlockDate = timestamp;
    }
    
    function lockInfo() public view returns(address, uint256, uint256) {
        return (vault, timelockStart, unlockDate);
    }

//--------------------------------------------------------------------------------------
//Function exclude addresses status / revoking exclude addresses status
//--------------------------------------------------------------------------------------
    
    mapping(address => bool) excluded;
    
    function shareExcluded(address account) public onlyOwner {
        excluded[account] = true;
    }
    
    function shareRevoke(address account) public onlyOwner {
        excluded[account] = false;
    }
    
    function isExcluded(address account) public view returns (bool) {
        return excluded[account];
    }

//--------------------------------------------------------------------------------------
//Function marking blacklist addresses status / revoking blacklist addresses status
//--------------------------------------------------------------------------------------

    mapping(address => bool) blacklist;
    
    function blacklistTag(address account) public onlyOwner {
        blacklist[account] = true;
    }
    
    function blacklistRevoke(address account) public onlyOwner {
        blacklist[account] = false;
    }
    
    function isBlacklist(address account) public view returns (bool) {
        return blacklist[account];
    }
    
//--------------------------------------------------------------------------------------
//Presale
//--------------------------------------------------------------------------------------
    
    event Purchase(address indexed _purchaser, uint256 _purchasedAmount, uint256 _bonusAmount);
    event ChangePriceRate (uint256 value);
    
    uint internal startDate;
    bool internal closed;
    
    uint256 internal presaleSupply = 400000 * (10**decimals);
    uint256 internal bonusPurchase = 200000 * (10**decimals);
    
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
        
        totalSupply = circulatingSupply.add(purchasedAmount + bonusAmount);
        
        presaleSupply = presaleSupply.sub(purchasedAmount);
        bonusPurchase = bonusPurchase.sub(bonusAmount);
        
        balances[msg.sender] = balances[msg.sender].add(purchasedAmount);
        balances[msg.sender] = balances[msg.sender].add(bonusAmount);
        
        require(!closed);
        
        emit Transfer(address(0), msg.sender, purchasedAmount);
        emit Transfer(address(0), msg.sender, bonusAmount);
        emit Purchase(msg.sender, purchasedAmount, bonusAmount);
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