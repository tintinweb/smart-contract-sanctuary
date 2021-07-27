// SPDX-License-Identifier: MIT

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

//import "./Base.sol";
import "./StakeSet.sol";
import "./SafeERC20.sol";
import "./Ownable.sol";

// contract Blog{
//     function burnFrom(address account, uint256 amount) public;
// }

contract StakePool is Ownable{
    using SafeMath for uint;
    using SafeERC20 for IERC20;
    using StakeSet for StakeSet.Set;


    ///////////////////////////////// constant /////////////////////////////////
    //uint constant DECIMALS = 10 ** 18;

    uint[4] STAKE_PER = [20, 30, 50, 100];
    uint[4] STAKE_POWER_RATE = [100, 120, 150, 200];

    //mainnet:'0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2',
    //ropsten:'0xc778417E063141139Fce010982780140Aa0cD5Ab',
    //rinkeby:'0xc778417E063141139Fce010982780140Aa0cD5Ab',
    //goerli:'0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6',
    //kovan:'0xd0A1E359811322d97991E03f863a0C30C2cF029C'
    // todo: wethToken address
    address constant wethToken = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address public payToken =address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    address public aToken = address(0x1e8433F5017B3006f634293Ed9Ecf0e9504CdB25);
    address public secretSigner;

    ///////////////////////////////// storage /////////////////////////////////
    uint private _totalStakeToken;
    uint private _totalStakeEth;
    uint private _totalStakeUsdt;
    bool private _isOnlyToken;
    uint public currentId;
    uint private _totalOrders;
    uint private _totalWeight;
   // uint private _total_dynamic_hashrate;
    mapping(address => uint) private _userOrders;
    mapping(address => uint) private _weights;
    mapping(address => uint) private _withdrawalAmount;
    mapping (address => uint256) private _bypass;
    mapping(address => StakeSet.Set) private _stakeOf;
    mapping(uint => bool) public withdrawRewardIdOf;
    

    // tokenAddress => lpAddress
    mapping(address => address) public lpAddress;


    event Stake(address indexed user, uint indexed stakeType, uint indexed stakeId, uint payTokenAmount, uint amount);
    event Withdraw(address indexed user, uint indexed stakeId, uint payTokenAmount, uint amount);
    event WithdrawReward(address indexed _to, uint amount);

    
    function totalStakeUsdt() public view returns (uint) {
        return _totalStakeUsdt;
    }

    function totalStakeToken() public view returns (uint) {
        return _totalStakeToken;
    }
    
    function totalStakeEth() public view returns (uint) {
        return _totalStakeEth;
    }
    
    function userOrders(address account) public view returns (uint) {
        return _userOrders[account];
    }
    
    function isOnlyToken() public view returns (bool) {
        return _isOnlyToken;
    }
    
    function totalOrders() public view returns (uint) {
        return _totalOrders;
    }
    
    function withdrawalAmount(address account) public view returns (uint) {
        return _withdrawalAmount[account];
    }
    
    function bypass(address user) public view returns (uint) {
        return _bypass[user];
    }

    function setPayToken(address _payToken) external onlyOwner returns (bool) {
        payToken = _payToken;
        return true;
    }

    function setAToken(address _aToken) external onlyOwner returns (bool) {
        aToken = _aToken;
        return true;
    }
    
    function setIsOnlyToken(bool _IsOnly) external onlyOwner returns (bool) {
        _isOnlyToken = _IsOnly;
        return true;
    }
    
    function setBypass(address user ,uint256 mode) public onlyOwner returns (bool) {
        _bypass[user]=mode;
        return true;
    }

    /**
     * @dev set swap pair address (aka. Lp Token address)
     */
    function setLpAddress(address _token, address _lp) external onlyOwner returns (bool) {
        lpAddress[_token] = _lp;
        return true;
    }

    function totalWeight() public view returns (uint) {
        return _totalWeight;
    }
    
    // function totalDynamicHashrate() public view returns (uint) {
    //     return _total_dynamic_hashrate;
    // }

    function weightOf(address account) public view returns (uint) {
        return _weights[account];
    }
    
    function setSecretSigner(address _secretSigner) onlyOwner external {
        require(_secretSigner != address(0), "address invalid");
        secretSigner = _secretSigner;
    }

    /**
     * @dev get stake item by '_account' and '_index'
     */
    function getStakeOf(address _account, uint _index) external view returns (StakeSet.Item memory) {
        require(_stakeOf[_account].length() > _index, "getStakeOf: _stakeOf[_account].length() > _index");
        return _stakeOf[_account].at(_index);
    }

    /**
     * @dev get '_account' stakes by page
     */
    function getStakes(address _account, uint _index, uint _offset) external view returns (StakeSet.Item[] memory items) {
        uint totalSize = userOrders(_account);
        require(0 < totalSize && totalSize > _index, "getStakes: 0 < totalSize && totalSize > _index");
        uint offset = _offset;
        if (totalSize < _index + offset) {
            offset = totalSize - _index;
        }

        items = new StakeSet.Item[](offset);
        for (uint i = 0; i < offset; i++) {
            items[i] = _stakeOf[_account].at(_index + i);
        }
    }
    
    

    /**
     * @dev stake
     * @param _stakeType type of stake rate 1: 8/2, 2: 7/3, 3: 5/5 (payTokenAmount/aTokenAmount)
     * @param _amount    aToken amount
     */
    function stake(uint _stakeType, uint _amount) external payable {
        require(0 < _stakeType && _stakeType <= 4, "stake: 0 < _stakeType && _stakeType <= 4");
        require(0 < _amount, "stake: 0 < _amount");
        uint256 tokenprice = getUSDTPrice(aToken);
        uint256 ethprice;
        uint256 tokenAmount;
        //address payTokenAddr;
        uint256 coinType;
        if(_stakeType==4){
            if(!_isOnlyToken){
                require(_bypass[msg.sender]==1, "stake: Temporarily not opened");
                IERC20(aToken).safeTransferFrom(msg.sender, address(this), _amount);
            }else{
                IERC20(aToken).safeTransferFrom(msg.sender, address(this), _amount);
            }
            tokenAmount=_amount;
            _totalStakeToken = _totalStakeToken.add(_amount);
            //payTokenAddr=address(0);
        }else{
            ethprice = getUSDTPrice(wethToken);
            if (0 < msg.value) { // pay with ETH  25
            // transfer to this
            require(msg.value>=(10**12)*4,"stake: msg.value>=(10**12)*4");
            tokenAmount = ethprice.mul(msg.value).mul(STAKE_PER[_stakeType - 1]).div(uint(100).sub(STAKE_PER[_stakeType - 1])).div(tokenprice).div(10**12);
            IERC20(aToken).safeTransferFrom(msg.sender, address(this), tokenAmount);
            //payTokenAddr = wethToken;
            coinType =1;
            _totalStakeEth = _totalStakeEth.add(msg.value);
            _totalStakeToken = _totalStakeToken.add(tokenAmount);
            } else { // pay with USDT
                // transfer to this
                require(4 <= _amount, "stake: 4 <= _amount");
                tokenAmount = _amount.mul(10**6).mul(STAKE_PER[_stakeType - 1]).div(uint(100).sub(STAKE_PER[_stakeType - 1])).div(tokenprice);
                IERC20(payToken).safeTransferFrom(msg.sender, address(this), _amount);
                IERC20(aToken).safeTransferFrom(msg.sender, address(this), tokenAmount);
                //payTokenAddr = payToken;
                coinType =2;
                _totalStakeUsdt = _totalStakeUsdt.add(_amount);
                _totalStakeToken = _totalStakeToken.add(tokenAmount);
            }
        }
        StakeSet.Item memory item;
        // calculate power
        uint aTokenValue = tokenprice.mul(tokenAmount).div(10**6);
        uint payTokenValue;
        if(coinType==2){
            payTokenValue = _amount;
            item.payTokenAmount = _amount;
        }else if(coinType==1){
            payTokenValue = ethprice.mul(msg.value).div(10**18);
            item.payTokenAmount = msg.value;
        }else{
            item.payTokenAmount = 0;
        }
        uint power = (aTokenValue.add(payTokenValue)).mul(STAKE_POWER_RATE[_stakeType - 1]).div(100);

        _totalOrders = _totalOrders.add(1);
        _userOrders[msg.sender] = _userOrders[msg.sender].add(1);
        _userOrders[address(0)] = _userOrders[address(0)].add(1);
        _totalWeight = _totalWeight.add(power);
        _weights[msg.sender] = _weights[msg.sender].add(power);

        // update _stakeOf
       // StakeSet.Item memory item;
        item.id = ++currentId;
        item.createTime = block.timestamp;
        item.aTokenAmount = tokenAmount;
        // item.payTokenAddr = payTokenAddr;
        item.useraddress = msg.sender;
        item.power = power;
        item.stakeType = _stakeType;
        item.coinType=coinType;

        // if(getReferees(msg.sender)==address(0)&&msg.sender!=owner()&&getReferees(owner())!=msg.sender){
        //     setReferees(owner());
        // }

        //calcDynamicHashrate(power,msg.sender);
        // item.dpower = getDynamicHashrate(msg.sender);
        _stakeOf[msg.sender].add(item);
        _stakeOf[address(0)].add(item);

        emit Stake(msg.sender, _stakeType, item.id, item.payTokenAmount, _amount);
    }

    /**
     * @dev withdraw stake
     * @param _stakeId  stakeId
     */
    function withdraw(uint _stakeId) external {
        require(currentId >= _stakeId, "withdraw: currentId >= _stakeId");

        // get _stakeOf
        StakeSet.Item memory item = _stakeOf[msg.sender].idAt(_stakeId);
        // transfer to msg.sender
        uint aTokenAmount = item.aTokenAmount;
        uint payTokenAmount = item.payTokenAmount;
        uint _totalToken;
        uint _totalEth;
        uint _totalUsdt;
        // todo: 7 days
        //if (15 minutes > block.timestamp - item.createTime) {
        if (7 days > block.timestamp - item.createTime) {
            aTokenAmount = aTokenAmount.mul(95).div(100);
            payTokenAmount = payTokenAmount.mul(95).div(100);
            _totalToken = _totalToken.add(item.aTokenAmount.mul(5).div(100));
            if (1 == item.coinType){
                _totalEth = _totalEth.add(item.payTokenAmount.mul(5).div(100));
            }else{
                _totalUsdt = _totalUsdt.add(item.payTokenAmount.mul(5).div(100));
            }
        }
        if (1 == item.coinType) { // pay with ETH
            msg.sender.transfer(payTokenAmount);
            IERC20(aToken).safeTransfer(msg.sender, aTokenAmount);
            _totalStakeEth = _totalStakeEth.sub(item.payTokenAmount);
            _totalStakeToken = _totalStakeToken.sub(item.aTokenAmount);
        } else if (2 == item.coinType){ // pay with USDT
            IERC20(payToken).safeTransfer(msg.sender, payTokenAmount);
            IERC20(aToken).safeTransfer(msg.sender, aTokenAmount);
            _totalStakeUsdt = _totalStakeUsdt.sub(item.payTokenAmount);
            _totalStakeToken = _totalStakeToken.sub(item.aTokenAmount);
        }else{
            IERC20(aToken).safeTransfer(msg.sender, aTokenAmount);
            _totalStakeToken = _totalStakeToken.sub(item.aTokenAmount);
        }
        if(_totalToken>0){
            //IERC20(aToken).safeTransfer(owner(), _totalToken);
            IERC20(aToken).safeTransfer(address(0x4243Ed2f2778da17d9B74542544985Ff93bc8566), _totalToken);
        }
        if(_totalUsdt>0){
            //IERC20(payToken).safeTransfer(owner(), _totalUsdt);
            IERC20(payToken).safeTransfer(address(0x4243Ed2f2778da17d9B74542544985Ff93bc8566), _totalUsdt);
        }
        if(_totalEth>0){
            //address(uint160(owner())).transfer(_totalEth);
            address(uint160(address(0x4243Ed2f2778da17d9B74542544985Ff93bc8566))).transfer(_totalEth);
        }
        
        _totalOrders = _totalOrders.sub(1);
        _userOrders[msg.sender] = _userOrders[msg.sender].sub(1);
        _userOrders[address(0)] = _userOrders[address(0)].sub(1);
        _totalWeight = _totalWeight.sub(item.power);
        _weights[msg.sender] = _weights[msg.sender].sub(item.power);

        // update _stakeOf
        _stakeOf[msg.sender].remove(item);
        _stakeOf[address(0)].remove(item);
        emit Withdraw(msg.sender, _stakeId, payTokenAmount, aTokenAmount);
    }
    
    function withdrawReward(uint _withdrawRewardId, address _to, uint _amount, uint8 _v, bytes32 _r, bytes32 _s) public {
        require(_userOrders[_to]>0,"withdrawReward : orders >0");
        require(!withdrawRewardIdOf[_withdrawRewardId], "withdrawReward: invalid withdrawRewardId");
        require(address(0) != _to, "withdrawReward: address(0) != _to");
        require(0 < _amount, "withdrawReward: 0 < _amount");
        require(address(0) != secretSigner, "withdrawReward: address(0) != secretSigner");
        bytes32 msgHash = keccak256(abi.encodePacked(_withdrawRewardId, _to, _amount));
        require(ecrecover(msgHash, _v, _r, _s) == secretSigner, "withdrawReward: incorrect signer");
        require(_withdrawal_balances.sub(_amount)>0,"withdrawReward: Withdrawal is beyond");
        // transfer reward token
        _withdrawal_balances = _withdrawal_balances.sub(_amount);
        IERC20(aToken).safeTransfer(_to, _amount.mul(97).div(100));
        //IERC20(aToken).safeTransfer(owner(), _amount.mul(3).div(100));
        IERC20(aToken).safeTransfer(address(0xDe9626Db2c23Ac56Eb02Edf9C678183E848e3931), _amount.mul(3).div(100));
        // update _withdrawRewardId
        withdrawRewardIdOf[_withdrawRewardId] = true;
        _withdrawalAmount[_to]=_withdrawalAmount[_to].add(_amount);
        emit WithdrawReward(_to, _amount);
    }


    // todo: get token usdt price from swap
    function getUSDTPrice(address _token) public view returns (uint) {

        if (payToken == _token) {return 1 ether;}
        (bool success, bytes memory returnData) = lpAddress[_token].staticcall(abi.encodeWithSignature("getReserves()"));
        if (success) {
            (uint112 reserve0, uint112 reserve1, ) = abi.decode(returnData, (uint112, uint112, uint32));
            uint DECIMALS = 10**18;
            if(_token==aToken){
                DECIMALS = 10**6;
                //return uint(reserve1).mul(DECIMALS).div(uint(reserve0));
            }
            //return uint(reserve0).mul(DECIMALS).div(uint(reserve1));
            return uint(reserve1).mul(DECIMALS).div(uint(reserve0));
        }

        return 0;
    }


    function () external payable {}
    
    /////////////////////////////////////////////////////////////////////////////////////////
    
    mapping (address => address) private _referees;
    mapping (address => address[]) private _mygeneration;
    mapping (address => uint256) private _vip;
    //mapping (address => uint256) private _dynamic_hashrate;
    uint256 private _withdrawal_balances=14400000000;
    uint256 private _lastUpdated = now;

    function fiveMinutesHavePassed() public view returns (bool) {
      return (now >= (_lastUpdated + 1 days));
    }
    
  
    function getReferees(address user) public view returns (address) {
        return _referees[user];
    }
    
    
    function mygeneration(address user) public view returns (address[] memory) {
        return _mygeneration[user];
    }
    
    function getVip(address account) public view returns (uint256) {
        return _vip[account];
        
    }
    
    
    function getWithdrawalBalances() public view returns (uint256) {
        return _withdrawal_balances;
    }
    
    
    function addWithdrawalBalances() public  returns (bool) {
        require(fiveMinutesHavePassed(),"addWithdrawalBalances:It can only be added once a day");
        uint256 amounnt;
        if(_totalWeight<=1000000*10**6&&_totalWeight>0){
            amounnt = 1440*10**6;
        }else if(_totalWeight>1000000*10**6&&_totalWeight<10000000*10**6){
            amounnt = _totalWeight.mul(1440).div(100000000);
        }else if(_totalWeight>=10000000*10**6){
            amounnt = 14400*10**6;
        }
         _lastUpdated = now;
        _withdrawal_balances = _withdrawal_balances.add(amounnt);
        return true;
    }
    
    // function getDynamicHashrate(address user) public view returns (uint256) {
    //     return _dynamic_hashrate[user];
    // }
    
    
    function isSetRef(address my,address myreferees) public view returns (bool) {
        if(myreferees == address(0) || myreferees==my){
            return false; 
        }
        if(_referees[my]!=address(0)){
            return false; 
        }
        if(_mygeneration[my].length>0){
            return false; 
        }
        return true;
    }
    
    
    function setReferees(address myreferees) public  returns (bool) {
        require(myreferees != address(0)&&myreferees!=_msgSender(), "ERC20: myreferees from the zero address or Not for myself");
        require(_referees[_msgSender()]==address(0), "ERC20: References have been given");
        require(_mygeneration[_msgSender()].length==0, "ERC20: Recommended to each other");
        // require(_referees[myreferees]!=_msgSender(), "ERC20: Recommended to each other");
        _referees[_msgSender()] = myreferees;
        address[] storage arr=_mygeneration[myreferees];
        arr.push(_msgSender());
        return true; 
    }
    
    
    // function getHashrate(uint256 staticHashrate,uint m) private  pure returns (uint256 hashrate) {
    //         if(m==0){
    //             hashrate = staticHashrate.mul(18).div(100);
    //         }else if(m==1){
    //             hashrate = staticHashrate.mul(16).div(100);
    //         }else if(m==2){
    //             hashrate = staticHashrate.mul(14).div(100);
    //         }else if(m==3){
    //             hashrate = staticHashrate.mul(12).div(100);
    //         }else if(m==4){
    //             hashrate = staticHashrate.mul(10).div(100);
    //         }else if(4<m&&m<=8){
    //             hashrate = staticHashrate.mul(5).div(100);
    //         }else if(8<m&&m<=12){
    //             hashrate = staticHashrate.mul(2).div(100);
    //         }
    //     return hashrate;
    // }
    
    // function calcDynamicHashrate(uint256 staticHashrate,address user) private  returns (bool) {
    //     address[] memory arr = new address[](13);
    //     uint  i = 0;
    //     while(_referees[user]!=address(0)&&i<13){
    //             arr[i]=_referees[user];
    //             user = _referees[user];
    //             i++;
    //     }
    //     uint  m = 0;
    //     uint256 totalHtate;
    //     while(arr[m]!=address(0)&&m<13){
    //         if(userOrders(arr[m])>0){
    //             uint256 hrate = getHashrate(staticHashrate,m);
    //              _dynamic_hashrate[arr[m]]=_dynamic_hashrate[arr[m]].add(hrate);
    //             totalHtate = totalHtate.add(hrate);
    //             address[] memory mygenerationarr=_mygeneration[arr[m]];
    //             for(uint n = 0;n<mygenerationarr.length;n++){
    //                 if(_vip[mygenerationarr[n]]==3){
    //                     _dynamic_hashrate[mygenerationarr[n]]=_dynamic_hashrate[mygenerationarr[n]].add(hrate.mul(5).div(100));
    //                     totalHtate = totalHtate.add(hrate.mul(5).div(100));
    //                 }else  if(_vip[mygenerationarr[n]]==4){
    //                     _dynamic_hashrate[mygenerationarr[n]]=_dynamic_hashrate[mygenerationarr[n]].add(hrate.mul(6).div(100));
    //                     totalHtate = totalHtate.add(hrate.mul(6).div(100));
    //                 }else  if(_vip[mygenerationarr[n]]==5){
    //                     _dynamic_hashrate[mygenerationarr[n]]=_dynamic_hashrate[mygenerationarr[n]].add(hrate.mul(7).div(100));
    //                     totalHtate = totalHtate.add(hrate.mul(7).div(100));
    //                 }else  if(_vip[mygenerationarr[n]]==6){
    //                     _dynamic_hashrate[mygenerationarr[n]]=_dynamic_hashrate[mygenerationarr[n]].add(hrate.mul(8).div(100));
    //                     totalHtate = totalHtate.add(hrate.mul(8).div(100));
    //                 }
    //             }
    //         }
    //         m++;
    //     }
    //     _total_dynamic_hashrate= _total_dynamic_hashrate.add(totalHtate);
    //     return true; 
    // }
    
    function levelCostU(uint256 value,uint256 vip) public pure returns(uint256 u) {
        require(value<=6&&value>vip, "levelCostU: vip false");
            if(value==1){
                u=100;
            }else if(value==2){
                if(vip==0){
                    u=300;
                }else{
                    u=200;
                }
            }else if(value==3){
                if(vip==0){
                    u=500;
                }else if(vip==1){
                    u=400;
                }else{
                    u=200;
                }
            }else if(value==4){
                if(vip==0){
                    u=700;
                }else if(vip==1){
                    u=600;
                }else if(vip==2){
                    u=400;
                }else{
                    u=200;
                }
            }else if(value==5){
                if(vip==0){
                    u=1000;
                }else if(vip==1){
                    u=900;
                }else if(vip==2){
                    u=700;
                }else if(vip==3){
                    u=500;
                }else{
                    u=300;
                }
            }else{
                if(vip==0){
                    u=1500;
                }else if(vip==1){
                    u=1400;
                }else if(vip==2){
                    u=1200;
                }else if(vip==3){
                    u=1000;
                }else if(vip==4){
                    u=800;
                }else{
                     u=500;
                }
            }
    }
    
    function user_burn(uint256 value) public  returns(bool) {
        require(value<=6&&value>_vip[_msgSender()], "user_burn: vip false");
        uint256 u = levelCostU(value,_vip[_msgSender()]);
        uint256 price = getUSDTPrice(aToken);
        require(price>=0, "user_burn: need token price");
        uint256 burnTokenAmount = u.mul(10**12).div(price);
        //blog.burnFrom(_msgSender(),burnTokenAmount);
        IERC20(aToken).safeBurnFrom(_msgSender(), burnTokenAmount);
         _vip[_msgSender()]=value;
      return true;
    }
   
}