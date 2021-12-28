// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./Include.sol";

struct SMake {
    address maker;
    bool    isBid;
    address asset;
    uint    volume;
    bytes32 currency;
    uint    price;
    uint    payType;
    uint    pending;
    uint    remain;
    uint    minVol;
    uint    maxVol;
    string link;
}

struct STake {
    uint    makeID;
    address taker;
    uint    vol;
    Status  status;
    uint    expiry;
}

enum Status { None, Paid, Cancel, Done, Appeal, Buyer, Seller }

contract DOTC is Configurable {
    using Address for address;
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    bytes32 internal constant _expiry_  = 'expiry';
    bytes32 internal constant _feeTo_  = 'feeTo';
    bytes32 internal constant _feeToken_  = 'feeToken';
    bytes32 internal constant _feeVolume_  = 'feeVolume';

    address public staking;
    address[] public arbiters;
    mapping (address => bool) public    isArbiter;
    mapping (address => uint) public    biddingN;
   
    SMake[]  public makes;
    STake[]  public takes;
    

    function makesN() public view returns(uint) {  return makes.length;    }
    function takesN() public view returns(uint) {  return takes.length;    }

    function __DOTC_init(address governor_, address staking_,address feeTo_, address feeToken_,uint feeVolume_) public initializer {
        __Governable_init_unchained(governor_);
        __DOTC_init_unchained(staking_,feeTo_,feeToken_,feeVolume_);
    }

    function __DOTC_init_unchained(address staking_,address feeTo_, address feeToken_,uint feeVolume_) public governance {
        staking = staking_;
        config[_expiry_]    = 30 minutes;
        config[_feeTo_] = uint(feeTo_);
        config[_feeToken_] = uint(feeToken_);
        config[_feeVolume_] = feeVolume_;
    }

    function setArbiters_(address[] calldata arbiters_) external governance {
        for(uint i=0; i<arbiters.length; i++)
            isArbiter[arbiters[i]] = false;
            
        arbiters = arbiters_;
        
        for(uint i=0; i<arbiters.length; i++)
            isArbiter[arbiters[i]] = true;
            
        emit SetArbiters(arbiters_);
    }
    event SetArbiters(address[] arbiters_);

    function make(bool isBid, address asset, uint volume, bytes32 currency, uint price,uint payType,uint minVol,uint maxVol,string memory link) virtual external returns(uint makeID) {
        require(volume > 0, 'volume should > 0');
        require(minVol <= maxVol , 'minVol must <= maxVol');
        require(maxVol <= volume, 'maxVol must <= volume');
        if(isBid) {
            require(staking == address(0) || IStaking(staking).enough(msg.sender));
            biddingN[msg.sender]++;
        } else
            IERC20(asset).safeTransferFrom(msg.sender, address(this), volume);
        makeID = makes.length;
        makes.push(SMake(msg.sender, isBid, asset, volume, currency, price,payType, 0, volume,minVol,maxVol,link));
        emit Make(makeID, msg.sender, isBid, asset, volume, currency, price,payType,minVol,maxVol,link);

    }
    event Make(uint indexed makeID, address indexed maker, bool isBid, address indexed asset, uint volume, bytes32 currency, uint price,uint payType,uint minVol,uint maxVol,string link);

    function cancelMake(uint makeID) virtual external returns (uint vol) {
        require(makes[makeID].maker != address(0), 'Nonexistent make order');
        require(makes[makeID].maker == msg.sender, 'only maker');
        require(makes[makeID].remain > 0, 'make.remain should > 0');
        //require(config[_disableCancle_] == 0, 'disable cancle');
        
        vol = makes[makeID].remain;
        if (!makes[makeID].isBid)
            IERC20(makes[makeID].asset).safeTransfer(msg.sender, vol);
        makes[makeID].remain = 0;

        emit CancelMake(makeID, msg.sender, makes[makeID].asset, vol);
    }
    event CancelMake(uint indexed makeID, address indexed maker, address indexed asset, uint vol);
    
    function reprice(uint makeID, uint newPrice) virtual external returns (uint vol, uint newMakeID) {
        require(makes[makeID].maker != address(0), 'Nonexistent make order');
        require(makes[makeID].maker == msg.sender, 'only maker');
        require(makes[makeID].remain > 0, 'make.remain should > 0');
        
        vol = makes[makeID].remain;
        newMakeID = makes.length;
        makes.push(SMake(msg.sender, makes[makeID].isBid, makes[makeID].asset, vol, makes[makeID].currency, newPrice, makes[makeID].payType, 0, vol,makes[makeID].minVol,makes[makeID].maxVol,makes[makeID].link));
        makes[makeID].remain = 0;
        
        emit CancelMake(makeID, msg.sender, makes[makeID].asset, vol);
        emit Make(newMakeID, msg.sender, makes[newMakeID].isBid, makes[newMakeID].asset, vol, makes[newMakeID].currency, newPrice,makes[makeID].payType,makes[makeID].minVol,makes[makeID].maxVol,makes[makeID].link);
        emit Reprice(makeID, newMakeID, msg.sender, makes[newMakeID].isBid, makes[newMakeID].asset, vol, makes[newMakeID].currency, makes[makeID].price, newPrice,makes[makeID].payType,makes[makeID].link);
    }
    event Reprice(uint indexed makeID, uint indexed newMakeID, address indexed maker, bool isBid, address asset, uint remain, bytes32 currency, uint price, uint newPrice,uint payType,string link);
    
    function take(uint makeID, uint volume) virtual external returns (uint takeID, uint vol) {
        require(makes[makeID].maker != address(0), 'Nonexistent make order');
        require(makes[makeID].remain > 0, 'make.remain should > 0');
        require(makes[makeID].minVol <= volume , 'volume must > minVol');
        require(makes[makeID].maxVol >= volume, 'volume must < maxVol');
        vol = volume;
        if(vol > makes[makeID].remain)
            vol = makes[makeID].remain;
            
        if(!makes[makeID].isBid) {
            require(staking == address(0) || IStaking(staking).enough(msg.sender));
            biddingN[msg.sender]++;
        } else
            IERC20(makes[makeID].asset).safeTransferFrom(msg.sender, address(this), vol);

        makes[makeID].remain = makes[makeID].remain.sub(vol);
        makes[makeID].pending = makes[makeID].pending.add(vol);
        
        takeID = takes.length;
        takes.push(STake(makeID, msg.sender, vol, Status.None, now.add(config[_expiry_])));
        
        emit Take(takeID, makeID, msg.sender, vol, takes[takeID].expiry);
    }
    event Take(uint indexed takeID, uint indexed makeID, address indexed taker, uint vol, uint expiry);

    function cancelTake(uint takeID) virtual external returns(uint vol) {
        require(takes[takeID].taker != address(0), 'Nonexistent take order');
        uint makeID = takes[takeID].makeID;
        (address buyer, address seller) = makes[makeID].isBid ? (makes[makeID].maker, takes[takeID].taker) : (takes[takeID].taker, makes[makeID].maker);

        if(msg.sender == buyer) {
            require(takes[takeID].status <= Status.Paid, 'buyer can cancel neither Status.None nor Status.Paid take order');
        } else if(msg.sender == seller) {
            require(takes[takeID].status == Status.None, 'seller can only cancel Status.None take order');
            require(takes[takeID].expiry < now, 'seller can only cancel expired take order');
        } else
            revert('only buyer or seller');

        biddingN[buyer] = biddingN[buyer].sub(1);
        vol = takes[takeID].vol;
        IERC20(makes[makeID].asset).safeTransfer(seller, vol);

        makes[makeID].pending = makes[makeID].pending.sub(vol);
        takes[takeID].status = Status.Cancel;

        emit CancelTake(takeID, makeID, msg.sender, vol);
    }
    event CancelTake(uint indexed takeID, uint indexed makeID, address indexed sender, uint vol);
    
    function paid(uint takeID) virtual external {
        require(takes[takeID].taker != address(0), 'Nonexistent take order');
        require(takes[takeID].status == Status.None, 'only Status.None');
        uint makeID = takes[takeID].makeID;
        address buyer = makes[makeID].isBid ? makes[makeID].maker : takes[takeID].taker;
        require(msg.sender == buyer, 'only buyer');

        takes[takeID].status = Status.Paid;
        takes[takeID].expiry = now.add(config[_expiry_]);

        emit Paid(takeID, makeID, buyer);
    }
    event Paid(uint indexed takeID, uint indexed makeID, address indexed buyer);

    function deliver(uint takeID) virtual external returns(uint vol) {
        require(takes[takeID].taker != address(0), 'Nonexistent take order');
        require(takes[takeID].status <= Status.Paid, 'only Status.None or Paid');
        uint makeID = takes[takeID].makeID;
        (address buyer, address seller) = makes[makeID].isBid ? (makes[makeID].maker, takes[takeID].taker) : (takes[takeID].taker, makes[makeID].maker);
        require(msg.sender == seller, 'only seller');

        biddingN[buyer] = biddingN[buyer].sub(1);
        vol = takes[takeID].vol;
        IERC20(makes[makeID].asset).safeTransfer(buyer, vol);

        makes[makeID].pending = makes[makeID].pending.sub(vol);
        takes[takeID].status = Status.Done;

        emit Deliver(takeID, makeID, seller, vol);
    }
    event Deliver(uint indexed takeID, uint indexed makeID, address indexed seller, uint vol);

    function appeal(uint takeID) virtual external {
        require(takes[takeID].taker != address(0), 'Nonexistent take order');
        require(takes[takeID].status == Status.Paid, 'only Status.Paid');
        uint makeID = takes[takeID].makeID;
        require(msg.sender == makes[makeID].maker || msg.sender == takes[takeID].taker, 'only maker or taker');
        require(takes[takeID].expiry < now, 'only expired');
        IERC20(address(config[_feeToken_])).safeTransferFrom(msg.sender, address(config[_feeTo_]), config[_feeVolume_]);
        takes[takeID].status = Status.Appeal;

        emit Appeal(takeID, makeID, msg.sender, takes[takeID].vol);
    }
    event Appeal(uint indexed takeID, uint indexed makeID, address indexed sender, uint vol);

    function arbitrate(uint takeID, Status status) virtual external returns(uint vol) {
        require(takes[takeID].taker != address(0), 'Nonexistent take order');
        require(takes[takeID].status == Status.Appeal, 'only Status.Appeal');
        require(isArbiter[msg.sender], 'only arbiter');

        uint makeID = takes[takeID].makeID;
        (address buyer, address seller) = makes[makeID].isBid ? (makes[makeID].maker, takes[takeID].taker) : (takes[takeID].taker, makes[makeID].maker);

        biddingN[buyer] = biddingN[buyer].sub(1);
        vol = takes[takeID].vol;
        if(status == Status.Buyer) {
            IERC20(makes[makeID].asset).safeTransfer(buyer, vol);
        } else if(status == Status.Seller) {
            IERC20(makes[makeID].asset).safeTransfer(seller, vol);
            if(staking.isContract())
                IStaking(staking).punish(buyer);
        } else
            revert('status should be Buyer or Seller');

        makes[makeID].pending = makes[makeID].pending.sub(vol);
        takes[takeID].status = status;

        emit Arbitrate(takeID, makeID, msg.sender, vol, status);
   }
    event Arbitrate(uint indexed takeID, uint indexed makeID, address indexed arbiter, uint vol, Status status);
    
    // Reserved storage space to allow for layout changes in the future.
    uint256[44] private ______gap;
}

interface IStaking {
    function enough(address buyer) external view returns(bool);
    function punish(address buyer) external;
}