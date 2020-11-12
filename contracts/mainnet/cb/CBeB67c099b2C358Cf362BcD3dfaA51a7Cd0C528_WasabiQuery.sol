// Dependency file: contracts/interface/IERC20.sol

//SPDX-License-Identifier: MIT
// pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}


// Dependency file: contracts/interface/IWasabi.sol

// pragma solidity >=0.5.0;

interface IWasabi {
    function getOffer(address  _lpToken,  uint index) external view returns (address offer);
    function getOfferLength(address _lpToken) external view returns (uint length);
    function pool(address _token) external view returns (uint);
    function increaseProductivity(uint amount) external;
    function decreaseProductivity(uint amount) external;
    function tokenAddress() external view returns(address);
    function addTakerOffer(address _offer, address _user) external returns (uint);
    function getUserOffer(address _user, uint _index) external view returns (address);
    function getUserOffersLength(address _user) external view returns (uint length);
    function getTakerOffer(address _user, uint _index) external view returns (address);
    function getTakerOffersLength(address _user) external view returns (uint length);
    function offerStatus() external view returns(uint amountIn, address masterChef, uint sushiPid);
    function cancel(address _from, address _sushi) external ;
    function take(address taker,uint amountWasabi) external;
    function payback(address _from) external;
    function close(address _from, uint8 _state, address _sushi) external  returns (address tokenToOwner, address tokenToTaker, uint amountToOwner, uint amountToTaker);
    function upgradeGovernance(address _newGovernor) external;
    function acceptToken() external view returns(address);
    function rewardAddress() external view returns(address);
    function getTokensLength() external view returns (uint);
    function tokens(uint _index) external view returns(address);
    function offers(address _offer) external view returns(address tokenIn, address tokenOut, uint amountIn, uint amountOut, uint expire, uint interests, uint duration);
    function getRateForOffer(address _offer) external view returns (uint offerFeeRate, uint offerInterestrate);
}


// Dependency file: contracts/interface/IWasabiOffer.sol

// pragma solidity >=0.5.0;

interface IWasabiOffer {
    function tokenIn() external view returns (address);
    function tokenOut() external view returns (address);
    function amountIn() external view returns (uint);
    function amountOut() external view returns (uint);
    function expire() external view returns (uint);
    function interests() external view returns (uint);
    function duration() external view returns (uint);
    function owner() external view returns (address);
    function taker() external view returns (address);
    function state() external view returns (uint);
    function pool() external view returns (address);
    function getEstimatedWasabi() external view returns(uint amount);
    function getEstimatedSushi() external view returns(uint amount);
}


// Root file: contracts/WasabiQuery.sol

pragma experimental ABIEncoderV2;
pragma solidity >=0.6.6;

// import 'contracts/interface/IERC20.sol';
// import 'contracts/interface/IWasabi.sol';
// import 'contracts/interface/IWasabiOffer.sol';

contract WasabiQuery {
    address public wasabi;
    address public owner;
    enum OfferState { Created, Opened, Taken, Paidback, Expired, Closed }

    struct OfferData {
        address tokenIn;
        address tokenOut;
        uint amountIn;
        uint amountOut;
        uint expire;
        uint interests;
        uint duration;
        uint state;
        uint feeRate;
        uint interestrate;
        uint wasabiReward;
        uint sushiReward;
        address owner;
        address taker;
    }

    event OwnerChanged(address indexed _oldOwner, address indexed _newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, 'Ownable: FORBIDDEN');
        _;
    }

    constructor(address _wasabi) public {
        owner = msg.sender;
        wasabi = _wasabi;
    }

    function changeOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), 'Ownable: INVALID_ADDRESS');
        emit OwnerChanged(owner, _newOwner);
        owner = _newOwner;
    }

    function changeWasabi(address _wasabi) public onlyOwner {
        wasabi = _wasabi;
    }

    function iterateOffers(address _token, uint _start, uint _end) public view returns (address[] memory) {
        if (_start > _end) return iterateReverseOffers(_token, _start, _end);

        uint count = IWasabi(wasabi).getOfferLength(_token);
        if (_end >= count) _end = count;
        require(_start <= _end && _start >= 0 && _end >= 0, "INVAID_PARAMTERS");
        address[] memory res = new address[](_end-_start);
        uint index = 0;
        for (uint i = _start; i < _end; i++) {
            res[index] = IWasabi(wasabi).getOffer(_token, i);
            index++;
        }
        return res;
    }

    function iterateReverseOffers(address _token, uint _start, uint _end) public view returns (address[] memory) {
        uint count = IWasabi(wasabi).getOfferLength(_token);
        if (_start >= count) _start = count;
        require(_end <= _start && _end >= 0 && _start >= 0, "INVAID_PARAMTERS");
        address[] memory res = new address[](_start-_end);
        if (_end == _start) return res;
        uint index = 0;
        uint len = 0;
        for (uint i = _start-1; i >= _end; i--) {
            res[index] = IWasabi(wasabi).getOffer(_token, i);
            index++;
            len++;
            if (len>=_start - _end) break;
        }
        return res;
    }

    function iterateUserOffers(uint _start, uint _end) public view returns (address[] memory) {
        if (_start > _end) return iterateReverseUserOffers(_start, _end);

        uint count = IWasabi(wasabi).getUserOffersLength(msg.sender);
        if (_end >= count) _end = count;
        require(_start <= _end && _start >= 0 && _end >= 0, "INVAID_PARAMTERS");
        address[] memory res = new address[](_end-_start);
        uint index = 0;
        for (uint i = _start; i < _end; i++) {
            res[index] = IWasabi(wasabi).getUserOffer(msg.sender, i);
            index++;
        }
        return res;
    }

    function iterateReverseUserOffers(uint _start, uint _end) public view returns (address[] memory) {
        uint count = IWasabi(wasabi).getUserOffersLength(msg.sender);
        if (_start >= count) _start = count;
        require(_end <= _start && _end >= 0 && _start >= 0, "INVAID_PARAMTERS");
        address[] memory res = new address[](_start-_end);
        if (_end == _start) return res;
        uint index = 0;
        uint len = 0;
        for (uint i = _start-1; i >= _end; i--) {
            res[index] = IWasabi(wasabi).getUserOffer(msg.sender, i);
            index++;
            len++;
            if (len>=_start - _end) break;
        }
        return res;
    }

    function iterateTakerOffers(uint _start, uint _end) public view returns (address[] memory) {
        if (_start > _end) return iterateReverseTakerOffers(_start, _end);

        uint count = IWasabi(wasabi).getTakerOffersLength(msg.sender);
        if (_end >= count) _end = count;
        require(_start <= _end && _start >= 0 && _end >= 0, "INVAID_PARAMTERS");
        address[] memory res = new address[](count);
        uint index = 0;
        for (uint i = _start; i < _end; i++) {
            res[index] = IWasabi(wasabi).getTakerOffer(msg.sender, i);
            index++;
        }
        return res;
    }

    function iterateReverseTakerOffers(uint _start, uint _end) public view returns (address[] memory) {
        uint count = IWasabi(wasabi).getTakerOffersLength(msg.sender);
        if (_start >= count) _start = count;
        require(_end <= _start && _end >= 0 && _start >= 0, "INVAID_PARAMTERS");
        address[] memory res = new address[](_start-_end);
        if (_end == _start) return res;
        uint index = 0;
        uint len = 0;
        for (uint i = _start-1; i >= _end; i--) {
            res[index] = IWasabi(wasabi).getTakerOffer(msg.sender, i);
            index++;
            len++;
            if (len>=_start - _end) break;
        }
        return res;
    }

    function getOfferInfo(address _offer) external view returns (OfferData memory offer) {
        (
            offer.tokenIn,
            offer.tokenOut,
            offer.amountIn,
            offer.amountOut,
            offer.expire,
            offer.interests,
            offer.duration
        ) = IWasabi(wasabi).offers(_offer);

        (offer.feeRate, offer.interestrate) = IWasabi(wasabi).getRateForOffer(_offer);
        offer.state = IWasabiOffer(_offer).state();
        if (offer.state == uint(OfferState.Taken) && block.number >= offer.expire) {
            offer.state = uint(OfferState.Expired);
        }
        offer.owner = IWasabiOffer(_offer).owner();
        offer.taker = IWasabiOffer(_offer).taker();

        offer.wasabiReward = IWasabiOffer(_offer).getEstimatedWasabi();
        offer.sushiReward = IWasabiOffer(_offer).getEstimatedSushi();
    }

    function iterateTokens(uint _start, uint _end) external view returns (address[] memory) {
        uint count = IWasabi(wasabi).getTokensLength();
        if (_end >= count) _end = count;
        require(_start <= _end && _start >= 0 && _end >= 0, "INVAID_PARAMTERS");
        address[] memory res = new address[](_end-_start);
        uint index = 0;
        for (uint i = _start; i < _end; i++) {
            res[index] = IWasabi(wasabi).tokens(i);
            index++;
        }
        return res;
    }
}