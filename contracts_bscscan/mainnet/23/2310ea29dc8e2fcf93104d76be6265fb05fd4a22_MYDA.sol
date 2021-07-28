/**
 *Submitted for verification at BscScan.com on 2021-07-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

struct StakeConfig {
    uint256 collateral;
    uint256 reward;
    uint256 lockTime;
    uint256 activeCollateral;  
    uint256 rewPaid; 
}

struct GeneralDetails {
    StakeConfig t1;
    StakeConfig t2;
    StakeConfig t3;
    
    string _name;
    string _symbol;
    uint8 _decimals;
    uint256 _totalSupply;
    bool _isPaused;
    uint256 _totalStake;   
    uint256 _activeStakers;
    uint256 _refPaid;
    uint256 _totalRewardPaid;
    
    address _validatorAdd;
    string _validatorApi;
    uint256 _maxSupply;
    uint256 _maxTxLimit;
    uint256 _rewardDuration;
    uint256 _refCom;
    uint256 _voteApproveRate;    
    uint256 _propDuration;
    uint256 _changeDate;
    uint256 _swapOut;
    uint256 _swapIn;
    uint256 _supplyTime;
    uint256 _otherSupply;
    address _stakeAddress;
}

struct StakeDetails {
    uint256 date;  
    uint256 rewDate;
    uint256 collateral;
    uint256 pendingRew;
    uint256 activeRew;
    uint256 refRew;
    uint256 rewPaid;
}

struct UserDetails {
    StakeDetails t1;
    StakeDetails t2;
    StakeDetails t3;
    
    uint256 _balances;
    uint256 voteStatus;
    uint256 propStatus;
    uint256 stakeNonce;
    address refAdd;
    uint256 refPaid;
    uint256 refCount;
    address[] refList;
} 

struct VoteData {
    address account;
    uint256 cycle;
    uint256 startDate;
    uint256 endDate;
    uint256 value;
    uint256 voteCount;
    string info;
    uint256 status;
}

abstract contract Context {
    
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    
}

interface AFTS {
    
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);      

    function isPaused() external view returns (bool);
    
    function generalDetails() external view returns(GeneralDetails memory);

    function userDetails(address account) external view returns(UserDetails memory);  
    
    function voteCycleDetails(uint256 cycle, string memory config) external view returns (VoteData memory);
    
    function swapInfo(uint256 nonceOut, bytes32 txid, uint256 method, address account) external view returns (uint256);
    
    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    function burn(uint256 amount, uint256 swapNonce, uint256 chainId) external returns (bool);
    
    function transferMulti(address[] memory to, uint256[] memory amount) external returns (bool);  
    
    function transferMultiFrom(address sender, address[] memory to, uint256[] memory amount) external returns (bool);    
    
    function stake(uint256[] memory info, address refAdd, bytes memory sig) external returns (bool);
    
    function propose(string memory config, string memory info, uint256 value, address account) external returns (bool);
    
    function vote(string memory config) external returns (bool);
    
    function mint(bytes32 txid, uint256 swapNonce, uint256 amount, uint256 fees, uint256 fromId, bytes memory sig) external returns (bool);   
    
    function protocolUpdate(uint256[] memory newConfig, address account, address stakeAddress, string memory info, uint256 status) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);    
    
    event Proposer(address indexed from, string config, uint256 value, address account);
    
    event Voter(address indexed from, string config);    
    
}

contract MYDA is Context, AFTS {
    
    GeneralDetails _general;
    
    mapping(string =>  uint256) private _genConfig;
    
    mapping(address =>  UserDetails) private _user;
    
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(uint256 =>  StakeConfig) _stakeConfig;
    
    mapping(address =>  mapping(uint256 =>  StakeDetails)) private _stake;
    
    mapping(address =>  mapping(bytes32 => uint256)) private _swapIn;
    
    mapping(address =>  mapping(uint256 => uint256)) private _swapOut;
    
    mapping(address =>  mapping(uint256 =>  mapping(string =>  uint256))) private _userVote;
    
    mapping(uint256 =>  mapping(string =>  VoteData)) private _vote;
    
    mapping(string =>  uint256) private _voteCycle;
    
    constructor () {
        _general._name = "MYDA";
        _general._symbol = "MYDA";
        _general._decimals = 18;
        _general._validatorAdd = _msgSender();
        _general._validatorApi = "https://validator.mydacoin.com/";
        _general._totalSupply = 100000000*1e18;
        _genConfig["maxSupply"] = 100000000*1e18;
        _genConfig["maxTxLimit"] = 200;
        _genConfig["rewardDuration"] = 86400;
        _genConfig["refCom"] = 10;  
        _genConfig["voteApproveRate"] = 70; 
        _genConfig["propDuration"] = 2592000;
        _stakeConfig[1].collateral = 5000*1e18;
        _stakeConfig[2].collateral = 10000*1e18;
        _stakeConfig[3].collateral = 20000*1e18;
        _stakeConfig[1].lockTime = 2592000;
        _stakeConfig[2].lockTime = 7776000;
        _stakeConfig[3].lockTime = 15552000;
        _stakeConfig[1].reward = 8.25*1e18;
        _stakeConfig[2].reward = 33*1e18;
        _stakeConfig[3].reward = 99*1e18;
        _general._isPaused = false;
        _general._stakeAddress = 0x7F7512BDcC61861DfEC5ad7C124899c72fC86FD6;
        _transfer(address(0), _general._stakeAddress, 100000000*1e18, 0);
    }

    function name() public view virtual override returns (string memory) {
        return _general._name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _general._symbol;
    }

    function decimals() public view virtual override returns (uint256) {
        return _general._decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _general._totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _user[account]._balances;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function isPaused() public view virtual override returns (bool) {
        return _general._isPaused;
    }   

    function generalDetails() public view virtual override returns(GeneralDetails memory){
        GeneralDetails memory gendet = _general;
        gendet.t1 = _stakeConfig[1];
        gendet.t2 = _stakeConfig[2];
        gendet.t3 = _stakeConfig[3];
        gendet._maxSupply = _genConfig["maxSupply"];
        gendet._maxTxLimit = _genConfig["maxTxLimit"];
        gendet._rewardDuration = _genConfig["rewardDuration"];
        gendet._refCom = _genConfig["refCom"];  
        gendet._voteApproveRate = _genConfig["voteApproveRate"]; 
        gendet._propDuration = _genConfig["propDuration"];
        return gendet;
    }
    
    function userDetails(address account) public view virtual override returns(UserDetails memory){
        UserDetails memory userdet = _user[account];
        userdet.t1 = _stake[account][1];
        
        if(_stake[_msgSender()][1].collateral > 0){
            userdet.t1.activeRew = ((((block.timestamp - _stake[_msgSender()][1].rewDate) / _genConfig["rewardDuration"]) * _stakeConfig[1].reward) * (_stake[_msgSender()][1].collateral / _stakeConfig[1].collateral));      
        }
        
        userdet.t2 = _stake[account][2];
        
        if(_stake[_msgSender()][2].collateral > 0){
            userdet.t2.activeRew = ((((block.timestamp - _stake[_msgSender()][2].rewDate) / _genConfig["rewardDuration"]) * _stakeConfig[2].reward) * (_stake[_msgSender()][2].collateral / _stakeConfig[2].collateral));
        }
        
        userdet.t3 = _stake[account][3];
        
        if(_stake[_msgSender()][3].collateral > 0){
            userdet.t3.activeRew = ((((block.timestamp - _stake[_msgSender()][3].rewDate) / _genConfig["rewardDuration"]) * _stakeConfig[3].reward) * (_stake[_msgSender()][3].collateral / _stakeConfig[3].collateral));
        }
        return userdet;
    }  
  
    function voteCycleDetails(uint256 cycle, string memory config) public view virtual override returns (VoteData memory) {
        
        if(cycle == 0){
            cycle = _voteCycle[config];
        }
        
        return _vote[cycle][config];
    }  
    
    function swapInfo(uint256 nonceOut, bytes32 txid, uint256 method, address account) public view virtual override returns (uint256) {
        
        if(method == 0){
            return _swapOut[account][nonceOut];
        } else {
            return _swapIn[account][txid];
        }
    }    

    function _transfer(address sender, address recipient, uint256 amount, uint8 method) internal virtual {
        require(!_general._isPaused, "Contract is Paused");
        
        if(method == 1){
            require(sender != address(0), "from zero address");
            require(recipient != address(0), "to zero address");
        }
        
        if(sender != address(0)){
            require(_user[sender]._balances >= amount, "amount exceeds balance");
            _user[sender]._balances -= amount;
        }
        
        if(recipient != address(0)){
            _user[recipient]._balances += amount;
        }
        
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(!_general._isPaused, "Contract is Paused");
        require(owner != address(0), "from zero address");
        require(spender != address(0), "to zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {     
        _transfer(_msgSender(), recipient, amount, 1);
        return true;
    }
    
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        require(_allowances[sender][_msgSender()] >= amount, "amount exceeds allowance");
        _transfer(sender, recipient, amount, 1);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }
    
    function _transferMulti(address sender, address[] memory to, uint256[] memory amount, uint8 method, address spender) internal virtual {
        require(sender != address(0), "from zero address");
		require(_general._maxTxLimit >= to.length, "greater than _maxTxLimit");        
		require(to.length == amount.length, "array length not equal");
		uint256 sum_;
		
        for (uint8 g; g < to.length; g++) {
            require(to[g] != address(0), "to zero address");
            sum_ += amount[g];            
        }
        
        require(_user[sender]._balances >= sum_, "amount exceeds balance");
        
        if(method == 1){
            require(_allowances[sender][spender] >= sum_, "amount exceeds allowance");
            _approve(sender, spender, _allowances[sender][_msgSender()] - sum_);            
        }
        
		for (uint8 i; i < to.length; i++) {
		    _transfer(sender, to[i], amount[i], 0);
		}        
    }   
   
	function transferMulti(address[] memory to, uint256[] memory amount) public virtual override returns (bool) {
		_transferMulti(_msgSender(), to, amount, 0, address(0));
        return true;
	}
	
	function transferMultiFrom(address sender, address[] memory to, uint256[] memory amount) public virtual override returns (bool) {
		_transferMulti(sender, to, amount, 1, _msgSender());
        return true;
	}  
	
    function stake(uint256[] memory info, address refAdd, bytes memory sig) public virtual override returns (bool) {//0-tier,1-qty,2-method,3-otherSupply
        _sigValidate(sig, keccak256(abi.encodePacked(_msgSender(), info[0], info[1], info[2], info[3], block.chainid, _user[_msgSender()].stakeNonce + 1, true)), _general._validatorAdd);
        _user[_msgSender()].stakeNonce += 1;
        if(_general._supplyTime < block.timestamp){
            _general._supplyTime = block.timestamp;
            _general._otherSupply = info[3];
        }
        _stakeProcess(_msgSender(), info[0], info[1], refAdd, info[2]);
        return true;
    }  
    
    function _stakeProcess(address recipient, uint256 tier, uint256 qty, address refAdd, uint256 method) internal virtual {
        require(!_general._isPaused, "Contract is Paused");
        require(recipient != address(0), "from zero address");
        require(tier > 0 && tier < 4, "Invalid Tier");
        require(method >= 0 && method < 4, "Invalid Method");
        
        if(method >=0 && method < 2){
            require(qty > 0, "Invalid Qty");
        }
        
        uint256 stakeReward;
        uint256 collateral;
        uint256 tempReward;
        uint256 diff;
        uint256 refRew;
        collateral = _stake[recipient][tier].collateral;
        refRew = _stake[recipient][tier].refRew;
        
        if(_user[recipient].refAdd == address(0) && refAdd != address(0) && refAdd != recipient){
            _user[recipient].refAdd = refAdd;
            _user[refAdd].refList.push(recipient);
            _user[refAdd].refCount += 1;
        }
        
        diff = (block.timestamp - _stake[recipient][tier].rewDate) / _genConfig["rewardDuration"];
        stakeReward = (((diff * _stakeConfig[tier].reward) * collateral) / _stakeConfig[tier].collateral) + _stake[recipient][tier].pendingRew;  
        
        if(method < 2){
            
            if(method == 0){
                require(!(_stake[_msgSender()][tier].collateral > 0), "Already Staking");
            } else {
                require(_stake[_msgSender()][tier].collateral > 0, "Staking Inactive");
            }
            
            _transfer(recipient, address(0), (_stakeConfig[tier].collateral * qty), 0);
            tempReward = ((_stakeConfig[tier].lockTime / _genConfig["rewardDuration"]) * _stakeConfig[tier].reward) * qty;
            refRew = ((tempReward * _genConfig["refCom"]) / 100);
            
            if(_user[_general._stakeAddress]._balances < (tempReward)){
                require(((_general._totalSupply + _general._otherSupply) + tempReward) <= _genConfig["maxSupply"], "Exceeds maxSupply");
            }
            
            if(_user[recipient].refAdd != address(0)){
                if(_user[_general._stakeAddress]._balances < (tempReward + refRew)){
                    require(((_general._totalSupply + _general._otherSupply) + tempReward + refRew) <= _genConfig["maxSupply"], "Exceeds maxSupply");
                }
                _stake[_user[recipient].refAdd][tier].refRew += refRew;
                _user[_user[recipient].refAdd].refPaid += refRew;
                _general._refPaid += refRew;
            }  
            
            if(method == 1){
                _stake[recipient][tier].pendingRew += stakeReward;
            }
            
            _stake[recipient][tier].date = block.timestamp;
            _stake[recipient][tier].rewDate = block.timestamp;
            _stake[recipient][tier].collateral += (_stakeConfig[tier].collateral * qty);
            _stakeConfig[tier].activeCollateral += (_stakeConfig[tier].collateral * qty);
            _user[recipient].propStatus = (tier == 3)?1:_user[recipient].propStatus;
            _general._totalStake += (_stakeConfig[tier].collateral * qty);
            
            if(_user[recipient].voteStatus == 0){
                _user[recipient].voteStatus = 1;
                _general._activeStakers += 1;
            }   
            
        } else {
            require(block.timestamp >= (_stake[_msgSender()][tier].date + _stakeConfig[tier].lockTime), "Stake not matured");
            require(_stake[_msgSender()][tier].collateral > 0, "Staking Inactive");
                
            if(_user[_general._stakeAddress]._balances < (stakeReward + refRew)){
                if(_user[_general._stakeAddress]._balances > 0){
                    stakeReward = _user[_general._stakeAddress]._balances;
                    refRew = 0;
                } else { 
                    stakeReward = 0;
                    refRew = 0;
                }                                
            }
            
            if(stakeReward > 0){
                _transfer(_general._stakeAddress, recipient, stakeReward + refRew, 1);
            } else {
                if(((_general._totalSupply + _general._otherSupply)) < _general._maxSupply){
                    if(((_general._totalSupply + _general._otherSupply) + stakeReward + refRew) > _genConfig["maxSupply"]){
                        if((_genConfig["maxSupply"] - (_general._totalSupply + _general._otherSupply)) > 0){
                            stakeReward = _genConfig["maxSupply"] - (_general._totalSupply + _general._otherSupply);
                            refRew = 0;
                        } else { 
                            stakeReward = 0;
                            refRew = 0;
                        }
                    }       
                    if(stakeReward > 0){
                        _general._totalSupply += stakeReward;
                        _transfer(address(0), recipient, stakeReward + refRew, 0);
                    }
                }

            }

            if(method == 2){
                _transfer(address(0), recipient, collateral, 0);
                _stake[recipient][tier].collateral = 0;
                _stake[recipient][tier].date = 0;
                _stake[recipient][tier].rewDate = 0;
                _general._totalStake -= collateral;
                _stakeConfig[tier].activeCollateral -= collateral;
                _user[recipient].propStatus = (tier == 3)?0:_user[recipient].propStatus;  
                if(_stake[recipient][1].collateral == 0 && _stake[recipient][2].collateral == 0 && _stake[recipient][3].collateral == 0){
                    _user[recipient].voteStatus = 0;
                    _general._activeStakers -= 1;
                }
            } else {
                _stake[recipient][tier].rewDate = block.timestamp;
            }
            
            _stake[recipient][tier].rewPaid += stakeReward;
            _stakeConfig[tier].rewPaid += stakeReward;
            _stake[recipient][tier].refRew = 0;
            _stake[recipient][tier].pendingRew = 0;
            _general._totalRewardPaid += stakeReward;             
        }
    }        

    function propose(string memory config, string memory info, uint256 value, address account) public virtual override returns (bool) {
        _propose(_msgSender(), config, info, value, account);
        return true;
    }
    
    function _propose(address sender, string memory config, string memory info, uint256 value, address account) internal {
        require(_user[sender].propStatus == 1, "Can't Propose");
        uint256 date = block.timestamp;
        uint256 cycle = _voteCycle[config];
        require((date - _vote[cycle][config].startDate) > _genConfig["propDuration"], "Old Active");
        _vote[cycle][config].status = 3;
        _voteCycle[config] += 1;
        cycle = _voteCycle[config];
        _vote[cycle][config].cycle = _voteCycle[config];
        _vote[cycle][config].startDate = date; 
        
        if(keccak256(bytes(config)) == keccak256(bytes("validatorAdd"))){
            _vote[cycle][config].account = account;
        } else {
            _vote[cycle][config].value = value; 
        }  
        
        _vote[cycle][config].status = 1;
        _vote[cycle][config].info = info;
        emit Proposer(sender, config, value, account);        
    }

    function vote(string memory config) public virtual override returns (bool) {
        _voteProcess(_msgSender(), config);
        return true;
    } 
    
    function _voteProcess(address sender, string memory config) internal {
        require(_user[sender].voteStatus == 1, "Can't Vote");
        uint256 date = block.timestamp;
        uint256 cycle = _voteCycle[config];
        require(_userVote[sender][cycle][config] == 0, "Already Voted");
        require(_vote[cycle][config].status == 1, "Voting Finished");
        _userVote[sender][cycle][config] = 1;
        _vote[cycle][config].voteCount += 1;
        
        if(_vote[cycle][config].voteCount >= ((_general._activeStakers * _genConfig["voteApproveRate"]) / 100)){
            
            if(keccak256(bytes(config)) == keccak256(bytes("maxSupply"))){
                require(keccak256(bytes(config)) == keccak256(bytes("maxSupply")) && _general._totalSupply < _vote[cycle][config].value, "less than totalSupply");
            }   
            
            _vote[cycle][config].status = 2;
            _vote[cycle][config].endDate = date;
            _general._changeDate = date;
            
            if(keccak256(bytes(config)) == keccak256(bytes("t1Collateral"))){
                _stakeConfig[1].collateral = _vote[cycle][config].value;
            } else if(keccak256(bytes(config)) == keccak256(bytes("t2Collateral"))){
                _stakeConfig[2].collateral = _vote[cycle][config].value;
            } else if(keccak256(bytes(config)) == keccak256(bytes("t3Collateral"))){
                _stakeConfig[3].collateral = _vote[cycle][config].value;
            } else if(keccak256(bytes(config)) == keccak256(bytes("t1Reward"))){
                _stakeConfig[1].reward = _vote[cycle][config].value;
            } else if(keccak256(bytes(config)) == keccak256(bytes("t2Reward"))){
                _stakeConfig[2].reward = _vote[cycle][config].value;
            } else if(keccak256(bytes(config)) == keccak256(bytes("t3Reward"))){
                _stakeConfig[3].reward = _vote[cycle][config].value;
            } else if(keccak256(bytes(config)) == keccak256(bytes("t1LockTime"))){
                _stakeConfig[1].lockTime = _vote[cycle][config].value;
            } else if(keccak256(bytes(config)) == keccak256(bytes("t2LockTime"))){
                _stakeConfig[2].lockTime = _vote[cycle][config].value;
            } else if(keccak256(bytes(config)) == keccak256(bytes("t3LockTime"))){
                _stakeConfig[3].lockTime = _vote[cycle][config].value;
            } else if(keccak256(bytes(config)) == keccak256(bytes("validatorAdd"))){
                _general._validatorAdd = _vote[cycle][config].account;
                _general._validatorApi = _vote[cycle][config].info;
            } else {
                _genConfig[config] = _vote[_voteCycle[config]][config].value;
            }           
        }        
        emit Voter(sender, config);        
    }

    function _splitSignature(bytes memory sig) internal pure returns (uint8, bytes32, bytes32) {
        require(sig.length == 65);
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
       return (v, r, s);
    }       
   
    function _sigValidate(bytes memory sig, bytes32 hash, address account) internal pure {
        (uint8 v, bytes32 r, bytes32 s) = _splitSignature(sig);
        require(ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), v, r, s) == account, "Not Authorized");
    }

    function burn(uint256 amount, uint256 swapNonce, uint256 chainId) public virtual override returns (bool) {
        _burn(_msgSender(), amount, swapNonce, chainId);
        return true;
    }

    function _burn(address sender, uint256 amount, uint256 swapNonce, uint256 chainId) internal {
        _transfer(sender, address(0), amount, 0);
        
        if(swapNonce > 0){
            _swapOut[sender][swapNonce] = chainId;
            _general._swapOut += amount;
        }
        
        _general._totalSupply -= amount;
    }    
    
    function mint(bytes32 txid, uint256 swapNonce, uint256 amount, uint256 fees, uint256 fromId, bytes memory sig) public virtual override returns (bool) {
        _mint(_msgSender(), txid, swapNonce, amount, fees, fromId, sig);
        return true;
    }  
    
    function _mint(address sender, bytes32 txid, uint256 swapNonce, uint256 amount, uint256 fees, uint256 fromId, bytes memory sig) internal {
        require(!_general._isPaused, "Contract is Paused");
        require(_swapIn[sender][txid] == 0, "Already Swapped");
        _sigValidate(sig, keccak256(abi.encodePacked(sender, txid, swapNonce, amount, fees, fromId, block.chainid, true)), _general._validatorAdd);
        _transfer(address(0), sender, amount - fees, 0);
        _transfer(address(0), _general._validatorAdd, fees, 0);
        _general._totalSupply += amount;
        _swapIn[sender][txid] = swapNonce;
        _general._swapIn += amount;
    }    
    
    function protocolUpdate(uint256[] memory newConfig, address account, address stakeAddress, string memory info, uint256 status) public virtual override returns (bool) {
        require(_msgSender() == _general._validatorAdd, "Only Validator Allowed");
        
        if(newConfig.length == 16){
            _genConfig["maxSupply"] = newConfig[0];
            _genConfig["maxTxLimit"] = newConfig[1];
            _genConfig["rewardDuration"] = newConfig[2];
            _genConfig["refCom"] = newConfig[3];  
            _genConfig["voteApproveRate"] = newConfig[4]; 
            _genConfig["propDuration"] = newConfig[5];
            _stakeConfig[1].collateral = newConfig[6];
            _stakeConfig[1].lockTime = newConfig[7];
            _stakeConfig[1].reward = newConfig[8];
            _stakeConfig[2].collateral = newConfig[9];
            _stakeConfig[2].lockTime = newConfig[10];
            _stakeConfig[2].reward = newConfig[11];
            _stakeConfig[3].collateral = newConfig[12];
            _stakeConfig[3].lockTime = newConfig[13];
            _stakeConfig[3].reward = newConfig[14];
            _general._changeDate = newConfig[15];
        }
        
        if(account != address(0)){
           _general._validatorAdd = account;
           _general._validatorApi = info;
        }
        
        if(stakeAddress != address(0)){
           _general._stakeAddress = stakeAddress;
        }
        
        if(status > 0){
            _general._isPaused = (status == 1)?true:false;
        }
        
        return true;
    } 

}