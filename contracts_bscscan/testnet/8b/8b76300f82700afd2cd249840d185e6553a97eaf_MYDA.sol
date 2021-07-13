/**
 *Submitted for verification at BscScan.com on 2021-07-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

abstract contract Context {
    
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    
}

interface IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);  

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    function burn(uint256 amount, uint256 swapNonce, uint256 chainId) external returns (bool);
    
    function transferMulti(address[] memory to, uint256[] memory amount) external returns (bool);  
    
    function transferMultiFrom(address sender, address[] memory to, uint256[] memory amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface OFTS {

    struct StakeConfig {
        uint256 collateral;
        uint256 reward;
        uint256 lockTime;
        uint256 activeCollateral;  
        uint256 rewPaid; 
    }
    
    struct GeneralDetails {
        //static
        string _name;
        string _symbol;
        uint8 _decimals;
        uint256 _totalSupply;
        
        //update by functions
        bool _isPaused;
        uint256 _totalStake;   
        uint256 _activeStakers;
        uint256 _refPaid;
        uint256 _totalRewardPaid;
        
        //config can be changed by voting/validator
        address _validatorAdd;
        uint256 _maxSupply;
        uint256 _maxTxLimit;
        uint256 _rewardDuration;
        uint256 _refCom;
        uint256 _voteApproveRate;    
        uint256 _propDuration;
        StakeConfig t1;
        StakeConfig t2;
        StakeConfig t3;
        uint256 _changeDate;
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
        uint256 _balances;
        uint256 voteStatus;
        uint256 propStatus;
        
        StakeDetails t1;
        StakeDetails t2;
        StakeDetails t3;
        
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
        uint256 activeStakers;
        uint256 status;
        uint256 result;
    } 
    
    struct VoteDetails {
        VoteData validatorAdd;  
        VoteData maxSupply;
        VoteData maxTxLimit;
        VoteData rewardDuration;
        VoteData refCom;
        VoteData propDuration;
        VoteData voteApproveRate;
        VoteData t1Collateral;
        VoteData t1Reward;
        VoteData t1LockTime;
        VoteData t2Collateral;
        VoteData t2Reward;
        VoteData t2LockTime;
        VoteData t3Collateral;
        VoteData t3Reward;
        VoteData t3LockTime;      
    }     
    
    function isPaused() external returns (bool);
    
    function generalDetails() external returns(GeneralDetails memory);

    function userDetails(address account) external returns(UserDetails memory);
    
    function voteDetails() external returns (VoteDetails memory);    
    
    function voteCycleDetails(uint256 cycle, string memory config) external returns (VoteData memory);
    
    function startStake(uint256 tier, uint256 qty, address refAdd) external returns (bool);
    
    function increaseStake(uint256 tier, uint256 qty, address refAdd) external returns (bool);
    
    function claimStake(uint256 tier, uint256 value) external returns (bool);
    
    function propose(string memory config, uint256 value, address account) external returns (bool);
    
    function vote(string memory config) external returns (bool);
    
    function chainSwap(bytes32 txid, uint256 swapNonce, uint256 amount, uint256 fees, uint256 chainId, bytes memory sig) external returns (bool);   
    
    function protocolUpdate(uint256[] memory newConfig, address account, uint256 status) external returns (bool);
    
    event Proposer(address indexed from, string config, uint256 value, address account);
    
    event Voter(address indexed from, string config);    
    
}

contract MYDA is Context, IERC20, OFTS {
    
    GeneralDetails _general;
    
    mapping(string =>  uint256) private _genConfig;
    
    mapping(address =>  UserDetails) private _user;
    
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(uint256 =>  StakeConfig) _stakeConfig;
    
    mapping(address =>  mapping(uint256 =>  StakeDetails)) private _stake;
    
    mapping(bytes32 => uint256) private _swapIn;
    
    mapping(uint256 => uint256) private _swapOut;
    
    mapping(address =>  mapping(uint256 =>  mapping(string =>  uint256))) private _userVote;
    
    mapping(uint256 =>  mapping(string =>  VoteData)) private _vote;
    
    mapping(string =>  uint256) private _voteCycle;
    
    constructor () {
        _general._name = "MYDA";
        _general._symbol = "MYDA";
        _general._decimals = 18;
        _general._validatorAdd = _msgSender();
        _general._totalSupply = 600000*1e18;
        _genConfig["maxSupply"] = 210000000*1e18;
        _genConfig["maxTxLimit"] = 200;
        _genConfig["rewardDuration"] = 10;
        _genConfig["refCom"] = 10;  
        _genConfig["voteApproveRate"] = 70; 
        _genConfig["propDuration"] = 60;
        _stakeConfig[1].collateral = 10000*1e18;
        _stakeConfig[2].collateral = 50000*1e18;
        _stakeConfig[3].collateral = 500000*1e18;
        _stakeConfig[1].lockTime = 60;
        _stakeConfig[2].lockTime = 120;
        _stakeConfig[3].lockTime = 180;
        _stakeConfig[1].reward = 0.25*1e18;
        _stakeConfig[2].reward = 0.5*1e18;
        _stakeConfig[3].reward = 0.75*1e18;
        _general._isPaused = false;
        _transfer(address(0), _msgSender(), 600000*1e18, 0);
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
        userdet.t1.activeRew = ((((block.timestamp - _stake[_msgSender()][1].rewDate) / _genConfig["rewardDuration"]) * _stakeConfig[1].reward) * (_stake[_msgSender()][1].collateral / _stakeConfig[1].collateral)) + _stake[_msgSender()][1].pendingRew;      
        userdet.t2 = _stake[account][2];
        userdet.t2.activeRew = ((((block.timestamp - _stake[_msgSender()][2].rewDate) / _genConfig["rewardDuration"]) * _stakeConfig[2].reward) * (_stake[_msgSender()][2].collateral / _stakeConfig[2].collateral)) + _stake[_msgSender()][2].pendingRew;
        userdet.t3 = _stake[account][3];
        userdet.t3.activeRew = ((((block.timestamp - _stake[_msgSender()][3].rewDate) / _genConfig["rewardDuration"]) * _stakeConfig[3].reward) * (_stake[_msgSender()][3].collateral / _stakeConfig[3].collateral)) + _stake[_msgSender()][3].pendingRew;
        return userdet;
    }  

    function voteDetails() public view virtual override returns (VoteDetails memory) {
        VoteDetails memory votedet;
        votedet.validatorAdd = _vote[_voteCycle["validatorAdd"]]["validatorAdd"];
        votedet.maxSupply = _vote[_voteCycle["maxSupply"]]["maxSupply"];
        votedet.maxTxLimit = _vote[_voteCycle["maxTxLimit"]]["maxTxLimit"];
        votedet.rewardDuration = _vote[_voteCycle["rewardDuration"]]["rewardDuration"];
        votedet.refCom = _vote[_voteCycle["refCom"]]["refCom"];
        votedet.propDuration = _vote[_voteCycle["propDuration"]]["propDuration"];
        votedet.voteApproveRate = _vote[_voteCycle["voteApproveRate"]]["voteApproveRate"];
        votedet.t1Collateral = _vote[_voteCycle["t1Collateral"]]["t1Collateral"];
        votedet.t1Reward = _vote[_voteCycle["t1Reward"]]["t1Reward"];
        votedet.t1LockTime = _vote[_voteCycle["t1LockTime"]]["t1LockTime"];
        votedet.t2Collateral = _vote[_voteCycle["t2Collateral"]]["t2Collateral"];
        votedet.t2Reward = _vote[_voteCycle["t2Reward"]]["t2Reward"];
        votedet.t2LockTime = _vote[_voteCycle["t2LockTime"]]["t2LockTime"];
        votedet.t3Collateral = _vote[_voteCycle["t3Collateral"]]["t3Collateral"];
        votedet.t3Reward = _vote[_voteCycle["t3Reward"]]["t3Reward"];
        votedet.t3LockTime = _vote[_voteCycle["t3LockTime"]]["t3LockTime"];        
        return votedet;
    }
    
    function voteCycleDetails(uint256 cycle, string memory config) public view virtual override returns (VoteData memory) {
        if(cycle == 0){
            cycle = _voteCycle[config];
        }
        return _vote[cycle][config];
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
	    require(!_general._isPaused, "Contract is Paused");
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
    
    function burn(uint256 amount, uint256 swapNonce, uint256 chainId) public virtual override returns (bool) {
        _transfer(_msgSender(), address(0), amount, 0);
        if(swapNonce > 0){
            _swapOut[swapNonce] = chainId;
        }
        _general._totalSupply -= amount;
        return true;
    }
     
    function startStake(uint256 tier, uint256 qty, address refAdd) public virtual override returns (bool) {        
        require(!(_stake[_msgSender()][tier].collateral > 0), "Already Staking");
        _stakeProcess(_msgSender(), tier, qty, refAdd, 0);
        return true;
    }  

    function increaseStake(uint256 tier, uint256 qty, address refAdd) public virtual override returns (bool) {
        require(_stake[_msgSender()][tier].collateral > 0, "Staking Inactive");
        _stakeProcess(_msgSender(), tier, qty, refAdd, 1);
        return true;
    } 
    
    function _stakeProcess(address sender, uint256 tier, uint256 qty, address refAdd, uint256 method) internal virtual {
        require(!_general._isPaused, "Contract is Paused");
        require(sender != address(0), "from zero address");
        require(tier > 0 && tier < 4, "Invalid Tier");
        require(tier >= 0 && tier < 4, "Invalid Method");
        uint256 stakeReward;
        uint256 collateral = (method < 2)?_stakeConfig[tier].collateral * qty:_stake[sender][tier].collateral;
        uint256 tempReward;
        uint256 diff;
        uint256 refRew = _stake[sender][tier].refRew;
        if(_user[sender].refAdd == address(0) && refAdd != address(0) && refAdd != sender){
            _user[sender].refAdd = refAdd;
            _user[refAdd].refList.push(sender);
            _user[refAdd].refCount = _user[refAdd].refCount + 1;
        }
        diff = (block.timestamp - _stake[sender][tier].rewDate) / _genConfig["rewardDuration"];
        stakeReward = (((diff * _stakeConfig[tier].reward) * collateral) / _stakeConfig[tier].collateral) + _stake[sender][tier].pendingRew;         
        if(method < 2){
            _transfer(sender, address(0), collateral, 0);
            tempReward = ((_stakeConfig[tier].lockTime / _genConfig["rewardDuration"]) * _stakeConfig[tier].reward) * qty;
            refRew = ((tempReward * _genConfig["refCom"]) / 100);    
            require((_general._totalSupply + tempReward) <= _genConfig["maxSupply"], "Exceeds maxSupply");
            if(_user[sender].refAdd != address(0)){
                require((_general._totalSupply + tempReward + refRew) <= _genConfig["maxSupply"], "Exceeds maxSupply");
                _stake[_user[sender].refAdd][tier].refRew = _stake[_user[sender].refAdd][tier].refRew + refRew;
                _user[_user[sender].refAdd].refPaid = _user[_user[sender].refAdd].refPaid + refRew;
                _general._refPaid = _general._refPaid + refRew;
            }  
            _stake[sender][tier].date = block.timestamp; 
            _stake[sender][tier].rewDate = block.timestamp;
            _stake[sender][tier].collateral += collateral;
            if(method == 1){
                _stake[sender][tier].pendingRew = stakeReward;
            }
            _stakeConfig[tier].activeCollateral += collateral;
            _user[sender].propStatus = (tier == 3)?1:0;
            _general._totalStake = _general._totalStake + collateral;
            if(_user[sender].voteStatus == 0){
                _user[sender].voteStatus = 1;
                _general._activeStakers = _general._activeStakers + 1;
            }            
        } else {
            if((_general._totalSupply + stakeReward + refRew) > _genConfig["maxSupply"]){
                uint256 remainSupply = _genConfig["maxSupply"] - _general._totalSupply;
                if(remainSupply > 0){
                    stakeReward = remainSupply;
                    refRew = 0;
                } else { 
                    stakeReward = 0;
                    refRew = 0;
                }
            }
            
            if(method == 2){
                _transfer(address(0), sender, collateral + stakeReward + refRew, 0);
                _stake[sender][tier].collateral = 0;
                _stake[sender][tier].date = 0;
                _general._totalStake -= collateral;
                _stakeConfig[tier].activeCollateral -= collateral;
                _user[sender].propStatus = (tier == 3 && _stake[sender][tier].collateral == 0)?0:_user[sender].propStatus;  
                if(_stake[sender][1].collateral == 0 && _stake[sender][2].collateral == 0 && _stake[sender][3].collateral == 0){
                    _user[sender].voteStatus = 0;
                    _general._activeStakers = _general._activeStakers - 1;
                }
            } else {
                require(stakeReward > 0, "Max Supply Reached Can't Claim Reward");
                _transfer(address(0), sender, stakeReward + refRew, 0);
            }
            
            _stake[sender][tier].rewPaid = _stake[sender][tier].rewPaid + stakeReward;
            _stakeConfig[tier].rewPaid = _stakeConfig[tier].rewPaid + stakeReward;
            _stake[sender][tier].refRew = 0;
            _stake[sender][tier].rewDate = 0;
            _stake[sender][tier].pendingRew = 0;
            _general._totalSupply = _general._totalSupply + stakeReward;
            _general._totalRewardPaid = _general._totalRewardPaid + stakeReward;        
        }
        
    }    

    function claimStake(uint256 tier, uint256 method) public virtual override returns (bool) {
        require(_stake[_msgSender()][tier].collateral > 0, "Staking Inactive");
        _stakeProcess(_msgSender(), tier, 0, address(0), method);
        return true;
    }

    function propose(string memory config, uint256 value, address account) public virtual override returns (bool) {
        require(_user[_msgSender()].propStatus == 1, "Can't Propose");
        uint256 date = block.timestamp;
        uint256 cycle = _voteCycle[config];
        require((date - _vote[cycle][config].startDate) > _genConfig["propDuration"], "Old Active");
        _voteCycle[config] = cycle + 1;
        cycle = _voteCycle[config];
        _vote[cycle][config].cycle = _voteCycle[config];
        _vote[cycle][config].startDate = date; 
        if(keccak256(bytes(config)) == keccak256(bytes("validatorAdd"))){
            _vote[cycle][config].account = account;
        } else {
            _vote[cycle][config].value = value; 
        }
        _vote[cycle][config].status = 1;  
        emit Proposer(_msgSender(), config, value, account);
        return true;
    }

    function vote(string memory config) public virtual override returns (bool) {
        require(_user[_msgSender()].voteStatus == 1, "Can't Vote");
        uint256 date = block.timestamp;
        uint256 cycle = _voteCycle[config];
        require(_userVote[_msgSender()][cycle][config] == 0, "Already Voted");
        require(_vote[cycle][config].status == 0, "Voting Finished");
        _userVote[_msgSender()][cycle][config] = 1;
        _vote[cycle][config].voteCount = _vote[cycle][config].voteCount + 1;
        if(_vote[cycle][config].voteCount >= ((_general._activeStakers * _genConfig["voteApproveRate"]) / 100)){
            if(keccak256(bytes(config)) == keccak256(bytes("maxSupply"))){
                require(keccak256(bytes(config)) == keccak256(bytes("maxSupply")) && _general._totalSupply < _vote[cycle][config].value, "less than totalSupply");
            }            
            _vote[cycle][config].status = 1;
            _vote[cycle][config].endDate = date;
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
            } else {
                _genConfig[config] = _vote[_voteCycle[config]][config].value;
            }           
        }        
        emit Voter(_msgSender(), config);
        return true;
    } 
    
    function splitSignature(bytes memory sig) internal virtual returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "Invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }    

    function chainSwap(bytes32 txid, uint256 swapNonce, uint256 amount, uint256 fees, uint256 chainId, bytes memory sig) public virtual override returns (bool) {
        require(!_general._isPaused, "Contract is Paused");
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(sig);
        require(_swapIn[txid] == 0, "Already Swapped");
        require(ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(_msgSender(), txid, swapNonce, amount, fees, chainId, true)))), v, r, s) == _general._validatorAdd, "Swap Not Approved or Valid");
        _transfer(address(0), _msgSender(), amount - fees, 0);
        _transfer(address(0), _general._validatorAdd, fees, 0);
        _general._totalSupply = _general._totalSupply + amount;
        _swapIn[txid] = swapNonce;
        return true;
    }    
    
    function protocolUpdate(uint256[] memory newConfig, address account, uint256 status) public virtual override returns (bool) {
        require(_msgSender() == _general._validatorAdd, "Not Approved to Update Config");
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
        }
        if(status > 0){
            _general._isPaused = (status == 1)?true:false;
        }
        return true;
    } 

}