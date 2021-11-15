// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// ERC721

import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "./base/BaseForwardUpgradeable.sol";
import "../interface/IHogletFactory.sol";
import "../library/TransferHelper.sol";

contract Forward721Upgradeable is BaseForwardUpgradeable, ERC721HolderUpgradeable {

    // orderId => tokenIds
    struct Asset {
        uint[] amounts;
    }
    mapping(uint => Asset) internal underlyingAssets_;

    function underlyingAssets(uint _orderId) external view returns (uint[] memory) {
        return underlyingAssets_[_orderId].amounts;
    }

    function __Forward721Upgradeable__init(
        address _want,
        uint _poolType,
        address _margin
    ) public initializer {
        __BaseForward__init(_want, _margin);
        require(_poolType == 721, "!721");
    }

    function createOrderFor(
        address _creator,
        uint[] memory _tokenIds, 
        // uint _orderValidPeriod,
        // uint _deliveryStart,
        // uint _deliveryPeriod,
        uint[] memory _times,
        // uint _deliveryPrice, 
        // uint _buyerMargin,
        // uint _sellerMargin,
        uint[] memory _prices,
        address[] memory _takerWhiteList,
        bool _deposit,
        bool _isSeller
    ) external {
        _onlyNotPaused();
        // check if msg.sender wants to deposit tokenId nft directly
        if (_deposit && _isSeller) {
            _pull721TokensToSelf(_tokenIds);
        }

        // create order
        _createOrderFor(
            _creator,
            // _orderValidPeriod,
            // _deliveryStart, 
            // _deliveryPeriod,
            _times,
            // _deliveryPrice, 
            // _buyerMargin, 
            // _sellerMargin,
            _prices,
            _takerWhiteList, 
            _deposit, 
            _isSeller
        );

        uint curOrderIndex = ordersLength - 1;
        for (uint i = 0; i < _tokenIds.length; i++) {
            underlyingAssets_[curOrderIndex].amounts.push(_tokenIds[i]);
        }
        
    }
    
    /**
    * @dev only maker or taker from orderId's order can invoke this method during challenge period
    * @param _orderId the order msg.sender wants to deliver
     */
    function _pullUnderlyingAssetsToSelf(uint _orderId) internal virtual override {
        _pull721TokensToSelf(underlyingAssets_[_orderId].amounts);
    }

    function _pushUnderlyingAssetsFromSelf(uint _orderId, address _to) internal virtual override {
        _push721FromSelf(underlyingAssets_[_orderId].amounts, _to);
    }
    

    function _onlyNotProtectedTokens(address _asset) internal virtual override view {
        require(_asset != margin, "!margin");
        require(_asset != fVault, "!fVault");
    }


    function _pull721TokensToSelf(uint[] memory _tokenIds) internal {
        for (uint i = 0; i < _tokenIds.length; i++) {
            TransferHelper._pullERC721(want, msg.sender, address(this), _tokenIds[i]);
        }
    }

    function _push721FromSelf(uint[] memory tokenIds, address to) internal {
        for (uint i = 0; i < tokenIds.length; i++) {
            TransferHelper._pushERC721(want, address(this), to, tokenIds[i]);
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal initializer {
        __ERC721Holder_init_unchained();
    }

    function __ERC721Holder_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../../interface/IHogletFactory.sol";
import "../../interface/IForwardVault.sol";


contract BaseForwardUpgradeable is Initializable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint;


    // use factory rather than Ownable's modifier to save gas
    address public factory;
    // want can be erc20, erc721, erc1155
    address public want; 
    // margin can be erc20 or ether--address(0)
    address public margin;
    // forward vault for margin token
    address public fVault;
    // info of eth 
    address public eth;
    // cumulative fee
    uint public cfee;
    // ratio = value of per share in forward : per share in fVault
    uint public ratio;
    // record orders.length
    uint public ordersLength;
    
    // forward contract status 
    bool public paused;

    enum State { inactive, active, filled, dead, delivery, expired, settled, canceled}

    struct Order {
        // using uint128 can help save 50k gas
        uint128 buyerMargin;
        uint128 sellerMargin;
        uint128 buyerShare;
        uint128 sellerShare;
        uint128 deliveryPrice;
        uint40 validTill;
        uint40 deliverStart;         // timpstamp
        uint40 expireStart;
        address buyer;
        address seller;
        bool buyerDelivered;
        bool sellerDelivered;
        State state;
        address[] takerWhiteList;
    }
    // here we use map rather than array to save gas
    mapping(uint => Order) public orders;


    // event
    event CreateOrder(uint orderId);
    event TakeOrder(uint orderId);
    event Delivery(uint orderId);
    event Settle(uint orderId);
    event CancelOrder(uint orderId);

    constructor() {}

    
    /***************** initializer begin **********************/
    function __BaseForward__init(
        address _want,
        address _margin
    ) public initializer {
        factory = msg.sender;
        IHogletFactory _factory = IHogletFactory(factory);
        require(_factory.ifMarginSupported(_margin), "!margin");
        want = _want;
        margin = _margin;
        ratio = 1e18;
    }
    /***************** initializer end **********************/


    /***************** condition check begin **********************/
    function _onlyFactory() internal view {
        require(msg.sender == factory, "!factory");
    }

    function _onlyNotPaused() internal view {
        require(!paused, "paused");
    }

    function _onlyNotProtectedTokens(address _token) internal virtual view {}

    /***************** condition check end **********************/
    

    /***************** authed function begin **********************/
    function pause() external {
        _onlyFactory();
        paused = true;
    }

    function unpause() external {
        _onlyFactory();
        paused = false;
    }

    function collectFee(address _to) external {
        address feeCollector = IHogletFactory(factory).feeCollector();
        require(msg.sender == factory || msg.sender == feeCollector, "!auth");
        _pushMargin(_to, cfee);
        cfee = 0;
    }

    function withdrawOther(address _token, address _to) external virtual {
        address feeCollector = IHogletFactory(factory).feeCollector();
        require(msg.sender == factory || msg.sender == feeCollector, "!auth");
        _onlyNotProtectedTokens(_token);

        if (_token == eth) {
            payable(_to).transfer(address(this).balance);
        } else {
            IERC20Upgradeable(_token).safeTransfer(_to, IERC20Upgradeable(_token).balanceOf(address(this)));
        }
    }

    function setForwardVault(address _fVault) external virtual {
        _onlyFactory();

        if (fVault == address(0) && _fVault != address(0)) {
            
            // enable vault first time
            address fvwant = IForwardVault(_fVault).want();
            require(fvwant == margin, "!want");
            // approve margin tokens for new forward vault
            IERC20Upgradeable(fvwant).safeApprove(_fVault, 0);
            IERC20Upgradeable(fvwant).safeApprove(_fVault, type(uint).max);

        } else if (fVault != address(0) && _fVault != address(0)) {
            
            // change vault from one to another one
            address fvwant = IForwardVault(_fVault).want();
            require(fvwant == margin, "!want");

            uint oldShares = IForwardVault(fVault).balanceOf(address(this));
            uint tokens = oldShares > 0 ? IForwardVault(fVault).withdraw(oldShares) : 0;

            IERC20Upgradeable(fvwant).safeApprove(fVault, 0);
            
            IERC20Upgradeable(fvwant).safeApprove(_fVault, 0);
            IERC20Upgradeable(fvwant).safeApprove(_fVault, type(uint).max);

            // ratio = oldShares > 0 ? IForwardVault(_fVault).deposit(tokens).mul(1e18).div(oldShares) : ratio;
            // we use the following to save gas
            if (oldShares > 0) {
                uint newShares = IForwardVault(_fVault).deposit(tokens);
                ratio = newShares.mul(1e18).div(oldShares);
            }

        } else if (fVault != address(0) && _fVault == address(0)) {
            
            // disable vault finally
            uint oldShares = IForwardVault(fVault).balanceOf(address(this));
            uint tokens = oldShares > 0 ? IForwardVault(fVault).withdraw(oldShares) : 0;
            
            // close approval
            IERC20Upgradeable(IForwardVault(fVault).want()).safeApprove(fVault, 0);
            // remember the ratio
            if (oldShares > 0) {
                ratio = tokens.mul(1e18).div(oldShares);
            }
        } else {
            revert("nonsense");
        }

        fVault = _fVault;
    }
    /***************** authed function end **********************/


    /***************** read function begin **********************/
    function balance() public view returns (uint) {
        return available().add(balanceSavingsInFVault());
    }

    function available() public view returns (uint) {
        return IERC20Upgradeable(margin).balanceOf(address(this));
    }
    
    function balanceSavingsInFVault() public view returns (uint) {
        return fVault == address(0) ? 0 : IForwardVault(fVault).balanceOf(address(this)).mul(
                                                        IForwardVault(fVault).getPricePerFullShare()
                                                    ).div(1e18);
    }

    function getPricePerFullShare() public view returns (uint) {
        return fVault == address(0) ? 
            ratio : 
            ratio.mul(IForwardVault(fVault).getPricePerFullShare()).div(1e18);
    }

    
    function getBuyerAmountToDeliver(uint _orderId) external virtual view returns (uint price) {
        Order memory order = orders[_orderId];        
        if (!order.buyerDelivered) {
            (uint fee, uint base) = IHogletFactory(factory).getOperationFee();
            uint buyerAmount = fee.add(base).mul(order.deliveryPrice).div(base);
            price = buyerAmount.sub(getPricePerFullShare().mul(order.buyerShare).div(1e18));
        }
    }

    /**
     * @dev return order state based on orderId
     * @param _orderId order index whose state to be checked.
     * @return 
            0--inactive: order not exist
            1--active: order has been successfully created 
            2--filled: order has been filled, 
            3--dead: order not filled till validTill timestamp, 
            4--delivery: order can be delivered, being challenged between buyer and seller,
            5--expired: order is expired, yet not settled
            6--settled: order has been successfully settled
            7--canceled: order has been created and then canceled since no taker
     */
    function checkOrderState(uint _orderId) public virtual view returns (State) {
        Order memory order = orders[_orderId];
        if (order.validTill == 0 ) return State.inactive;
        if (order.state == State.canceled) return State.canceled;
        uint time = _getBlockTimestamp();
        if (time <= order.validTill) {
            if (order.state != State.filled) return State.active;
            return State.filled;
        }
        if (order.state == State.active) return State.dead;
        if (time <= order.deliverStart) {
            if (order.state != State.filled) return State.dead;
            return State.filled;
        }
        if (time <= order.expireStart) {
            if (order.state != State.settled) return State.delivery;
            return State.settled;
        }
        if (order.state != State.settled) return State.expired;
        return State.settled; // can only be settled
    }

    function getOrder(uint _orderId) external virtual view returns (Order memory order) {
        order = orders[_orderId];
    }
    function version() external virtual view returns (string memory) {
        return "v1.0";
    }
    /***************** read function end **********************/


    /***************** write function begin **********************/
    function cancelOrder(uint _orderId) external virtual {
        _onlyNotPaused();
        require(checkOrderState(_orderId)== State.dead, "!dead");
        _cancelOrder(_orderId);
    }
    function takeOrderFor(address _taker, uint _orderId) external virtual {
        _onlyNotPaused();
        require(checkOrderState(_orderId)== State.active, "!active");
        _takeOrderFor(_taker, _orderId);
    }
    
    function deliverFor(address _deliverer, uint _orderId) external virtual {
        _onlyNotPaused();
        require(checkOrderState(_orderId) == State.delivery, "!delivery");
        _deliverFor(_deliverer, _orderId);
    }

    function settle(uint _orderId) external virtual{
        _onlyNotPaused();
        require(checkOrderState(_orderId) == State.expired, "!expired");
        // delivery time has past, anyone can forcely settle/exercise this order
        _settle(_orderId, true);
    }
    /***************** write function end **********************/

    
    /***************** internal function start **********************/
    function _createOrderFor(
        address _creator,
        // uint _orderValidPeriod,
        // uint _deliveryStart,
        // uint _deliveryPeriod,
        uint[] memory _times,
        // uint _deliveryPrice, 
        // uint _buyerMargin,
        // uint _sellerMargin,
        uint[] memory _prices,
        address[] memory _takerWhiteList,
        bool _deposit,
        bool _isSeller
    ) internal virtual {
        require(_prices[0] < type(uint128).max && _prices[1] < type(uint128).max && _prices[2] < type(uint128).max, "overflow");
        require(uint(_prices[1].add(_prices[2])) < type(uint128).max, "deliver may overflow");
        require(uint(_times[1]).add(_times[2]) < type(uint40).max && _getBlockTimestamp().add(_times[0]) < uint(_times[1]), "!time");
        uint128 _shares;
        if (_deposit && !_isSeller) {
            (uint fee, uint base) = IHogletFactory(factory).getOperationFee();
            _shares = _pullMargin(fee.add(base).mul(_prices[0]).div(base), true);
        } else {
            // take margin from msg.sender normally
            _shares = _pullMargin(_isSeller ? _prices[2] : _prices[1], true);
        }

        uint index = ordersLength++;
        orders[index] = Order({
            buyer: _isSeller ? address(0) : _creator,
            buyerMargin: uint128(_prices[1]),
            buyerShare: _isSeller ? 0 : _shares,
            buyerDelivered: _deposit && !_isSeller,
            seller: _isSeller ? _creator : address(0),
            sellerMargin: uint128(_prices[2]),
            sellerShare: _isSeller ? _shares : 0,
            sellerDelivered: _deposit && _isSeller,
            deliveryPrice: uint128(_prices[0]),
            validTill: uint40(_getBlockTimestamp().add(_times[0])),
            deliverStart: uint40(_times[1]),
            expireStart: uint40(_times[1].add(_times[2])),
            state: State.active,
            takerWhiteList: new address[](0)
        });
        
        if (_takerWhiteList.length > 0) {
            for (uint i = 0; i < _takerWhiteList.length; i++) {
                orders[index].takerWhiteList.push(_takerWhiteList[i]);
            }
        }
        emit CreateOrder(index);
    
    }

    function _cancelOrder(uint _orderId) internal virtual {
        Order memory order = orders[_orderId];
        // return margin to maker, underlyingAssets to maker if deposit
        if (order.buyer != address(0)) {
            _pushMargin(order.buyer, getPricePerFullShare().mul(order.buyerShare).div(1e18));
        } else if (order.seller != address(0)) {
            _pushMargin(order.seller, getPricePerFullShare().mul(order.sellerShare).div(1e18));
            if (order.sellerDelivered) _pushUnderlyingAssetsFromSelf(_orderId, order.seller);
        } else {
            revert("cancelOrder bug");
        }

        // mark order as canceled
        orders[_orderId].state = State.canceled;
        emit CancelOrder(_orderId);
    }


    function _takeOrderFor(address _taker, uint _orderId) internal virtual {
        Order memory order = orders[_orderId];
        if (order.takerWhiteList.length > 0) require(_withinList(_taker, order.takerWhiteList), "!whitelist");

        uint128 shares = _pullMargin(
            orders[_orderId].seller == address(0) ? orders[_orderId].sellerMargin : orders[_orderId].buyerMargin,
            true
        );

        // change storage
        if (orders[_orderId].buyer == address(0)) {
            orders[_orderId].buyer = _taker;
            orders[_orderId].buyerShare = shares;
        } else if (orders[_orderId].seller == address(0)) {
            orders[_orderId].seller = _taker;
            orders[_orderId].sellerShare = shares;
        } else {
            revert("takeOrder bug");
        }
        orders[_orderId].state = State.filled;
        emit TakeOrder(_orderId);
    }
    

    function _deliverFor(address _deliverer, uint _orderId) internal virtual {
        Order memory order = orders[_orderId];


        if (_deliverer == order.seller && !order.sellerDelivered) {
            // seller tends to deliver underlyingAssets[_orderId] amount of want tokens
            _pullUnderlyingAssetsToSelf(_orderId);
            orders[_orderId].sellerDelivered = true;
            emit Delivery(_orderId);
        } else if (_deliverer == order.buyer && !order.buyerDelivered) {
            // buyer tends to deliver tokens
            (uint fee, uint base) = IHogletFactory(factory).getOperationFee();
            uint debt = fee.add(base).mul(order.deliveryPrice).div(base);
            _pullMargin(
                debt.sub(getPricePerFullShare().mul(order.buyerShare).div(1e18)), 
                false /* here we do not farm delivered tokens since they just stay in contract for delivery period at most */
            );  
            orders[_orderId].buyerDelivered = true;
            emit Delivery(_orderId);
        } else {
            revert("deliver bug");
        }

        // soft settle means settle if necessary otherwise wait for the counterpart to deliver or the order to expire
        _settle(_orderId, false); 
    }


    function _settle(uint _orderId, bool _forceSettle) internal {
        (uint fee, uint base) = IHogletFactory(factory).getOperationFee();
        Order memory order = orders[_orderId];
        // in case both sides delivered
        if (order.sellerDelivered && order.buyerDelivered) {
            // send buyer underlyingAssets[_orderId] amount of want tokens and seller margin
            _pushUnderlyingAssetsFromSelf(_orderId, order.buyer);
            uint bfee = fee.mul(order.deliveryPrice).div(base);
            // carefully check if there is margin left for buyer in case buyer depositted both margin and deliveryPrice at the very first
            uint bsa /*Buyer Share token Amount*/ = getPricePerFullShare().mul(order.buyerShare).div(1e18);
            // should send extra farmming profit to buyer
            if (bsa > bfee.add(order.deliveryPrice)) {
                _pushMargin(order.buyer, bsa.sub(order.deliveryPrice).sub(bfee));
            }
            
            // send seller payout
            uint sellerAmount = getPricePerFullShare().mul(order.sellerShare).div(1e18).add(order.deliveryPrice).sub(bfee);
            _pushMargin(order.seller, sellerAmount);
            cfee = cfee.add(bfee.mul(2));
            
            
            orders[_orderId].state = State.settled;
            emit Settle(_orderId);
            return; // must return here
        }
        if (_forceSettle) {
            if (!order.sellerDelivered) {
                // blame seller if he/she does not deliver nfts  
                uint sfee = fee.mul(order.sellerMargin).div(base);
                cfee = cfee.add(sfee);
                _pushMargin(
                    order.buyer, 
                    /* here we send both buyer and seller's margin to buyer except seller's op fee */
                    uint(order.buyerShare).add(order.sellerShare).mul(getPricePerFullShare()).div(1e18).sub(sfee)
                );
            } else if (!order.buyerDelivered) {
                // blame buyer
                uint bfee = fee.mul(order.buyerMargin).div(base);
                cfee = cfee.add(bfee);
                _pushMargin(
                    order.seller,
                    uint(order.sellerShare).add(order.buyerShare).mul(getPricePerFullShare()).div(1e18).sub(bfee)
                );
                // return underying assets (underlyingAssets[_orderId] amount of want) to seller
                _pushUnderlyingAssetsFromSelf(_orderId, order.seller);
            }
            orders[_orderId].state = State.settled;
            emit Settle(_orderId);
        }
    }



    
    function _pullMargin(uint _amount, bool _farm) internal virtual returns (uint128) {
        _pullTokensToSelf(margin, _amount);
        uint shares = _farm && fVault != address(0) ? 
                    IForwardVault(fVault).deposit(_amount).mul(1e18).div(ratio)
                    :
                    _amount.mul(1e18).div(getPricePerFullShare());
        return uint128(shares); // won't overflow since both _amount/ratio and 1e18/getPricePerFullShare < 1
    }

    function _pushMargin(address _to, uint _amount) internal virtual  {
        // check if balance not enough, if not, withdraw from vault
        uint ava = available();
        if (ava < _amount && fVault != address(0)) {
            IForwardVault(fVault).withdraw(_amount.sub(ava));
            ava = available();
        }
        if (_amount > ava) _amount = ava;
        _pushTokensFromSelf(margin, _to, _amount);
    }
    

    function _pullTokensToSelf(address _token, uint _amount) internal virtual {
        // below check is not necessary since we would check supported margin is untaxed
        // uint mtOld = IERC20Upgradeable(_token).balanceOf(address(this));
        IERC20Upgradeable(_token).safeTransferFrom(msg.sender, address(this), _amount);
        // uint mtNew = IERC20Upgradeable(_token).balanceOf(address(this));
        // require(mtNew.sub(mtOld) == _amount, "!support taxed token");
        
    }
    
    function _pushTokensFromSelf(address _token, address _to, uint _amount) internal virtual {
        IERC20Upgradeable(_token).safeTransfer(_to, _amount);
    }


    function _withinList(address addr, address[] memory list) internal pure returns (bool) {
        for (uint i = 0; i < list.length; i++) {
            if (addr == list[i]) return true;
        }
        return false;
    }

    function _getBlockTimestamp() internal view returns (uint) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp;
    }

    function _pullUnderlyingAssetsToSelf(uint _orderId) internal virtual {}
    function _pushUnderlyingAssetsFromSelf(uint _orderId, address _to) internal virtual {}
    /***************** internal function end **********************/
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../proxy/beacon/IBeacon.sol";
interface IHogletFactory is IBeacon {
    
    
    // read methods
    function ifMarginSupported(address coin) external view returns (bool);
    function getOperationFee() external view returns (uint fee, uint base);
    function feeCollector() external view returns (address);
    function version() external returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/*
Already support:
CryptoPunks: https://etherscan.io/address/0xb47e3cd837ddf8e4c57f05d70ab865de6e193bbb#code
CryptoKitties: https://etherscan.io/address/0x06012c8cf97bead5deae237070f9587f8e7a266d#code
CryptoVoxels: https://etherscan.io/address/0x79986af15539de2db9a5086382daeda917a9cf0c
Axie Infinity Axies: https://etherscan.io/address/0xf5b0a3efb8e8e4c201e2a935f110eaaf3ffecb8d (it does not check selector, so safeTransferFrom is not safe but works fine)
Blockchain Cuties: https://etherscan.io/address/0xd73be539d6b2076bab83ca6ba62dfe189abc6bbe (it does not check selector, so safeTransferFrom is not safe but works fine)
Makersplace v2: https://etherscan.io/address/0x2a46f2ffd99e19a89476e2f62270e0a35bbf0756 (problem same as CryptoVoxels, wrong selector, we can only use transferFrom)
*/
library TransferHelper {

    // Non-standard ERC721 projects:  https://docs.niftex.org/general/supported-nfts
    // implementation refers to: https://github.com/NFTX-project/nftx-protocol-v2/blob/master/contracts/solidity/NFTXVaultUpgradeable.sol#L444
    // TODO: improve implemention to include more non-standard ERC721 impl and change standard to safe-(invoke) way
    function _pushERC721(address assetAddr, address from, address to, uint256 tokenId) internal {
        address kitties = 0x06012c8cf97BEaD5deAe237070F9587f8E7A266d;
        address punks = 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;
        address voxels = 0x79986aF15539de2db9A5086382daEdA917A9CF0C;
        address makersTokenV2 = 0x2A46f2fFD99e19a89476E2f62270e0a35bBf0756;
        bytes memory data;
        if (assetAddr == kitties) {
            // data = abi.encodeWithSignature("transfer(address,uint256)", to, tokenId); 
            // bytes4(keccak256(bytes('transfer(address,uint256)'))) == 0xa9059cbb
            data = abi.encodeWithSelector(0xa9059cbb, to, tokenId); // save gas
        } else if (assetAddr == punks) {
            // CryptoPunks.
            // data = abi.encodeWithSignature("transferPunk(address,uint256)", to, tokenId);
            data = abi.encodeWithSelector(0x8b72a2ec, to, tokenId); // save gas
        } else if (assetAddr == voxels || assetAddr == makersTokenV2){
            // crypto voxels, wrong selector id, we need to use transferFrom
            // data = abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, tokenId);
            data = abi.encodeWithSelector(0x23b872dd, from, to, tokenId); // save gas
        } else {
            // Default.
            // data = abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", from, to, tokenId);
            data = abi.encodeWithSelector(0x42842e0e, from, to, tokenId); // save gas
        }
        (bool success, bytes memory result) = address(assetAddr).call(data);
        require(success && result.length == 0);
    }

    function _pullERC721(address assetAddr, address from, address to, uint256 tokenId) internal {
        address kitties = 0x06012c8cf97BEaD5deAe237070F9587f8E7A266d;
        address punks = 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;
        address voxels = 0x79986aF15539de2db9A5086382daEdA917A9CF0C;
        address makersTokenV2 = 0x2A46f2fFD99e19a89476E2f62270e0a35bBf0756;
        bytes memory data;
        if (assetAddr == kitties) {
            // Cryptokitties.
            // data = abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, tokenId);
            data = abi.encodeWithSelector(0x23b872dd, from, to, tokenId);  // save gas
        } else if (assetAddr == punks) {
            // CryptoPunks.
            // Fix here for frontrun attack. Added in v1.0.2.
            // (bool checkSuccess, bytes memory result) = address(assetAddr).staticcall(abi.encodeWithSignature("punkIndexToAddress(uint256)", tokenId));
            (bool checkSuccess, bytes memory result) = address(assetAddr).staticcall(abi.encodeWithSelector(0x58178168, tokenId)); // save gas
            (address owner) = abi.decode(result, (address));
            require(checkSuccess && owner == from, "pull not owner");
            // data = abi.encodeWithSignature("buyPunk(uint256)", tokenId);
            data = abi.encodeWithSelector(0x8264fe98, tokenId); // save gas
        } else if (assetAddr == voxels || assetAddr == makersTokenV2) {
            // data = abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, tokenId);
            data = abi.encodeWithSelector(0x23b872dd, from, to, tokenId); // save gas
        } else {
            // Default.
            // data = abi.encodeWithSignature("safeTransferFrom(address,address,uint256)", from, to, tokenId);
            data = abi.encodeWithSelector(0x42842e0e, from, to, tokenId); // save gas
        }
        (bool success, bytes memory resultData) = address(assetAddr).call(data);
        require(success && resultData.length == 0);
    }

    function _approveERC721(address assetAddr, address owner, address spender, uint256 tokenId) internal {
        address kitties = 0x06012c8cf97BEaD5deAe237070F9587f8E7A266d;
        address punks = 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB;
        address voxels = 0x79986aF15539de2db9A5086382daEdA917A9CF0C;
        address makersTokenV2 = 0x2A46f2fFD99e19a89476E2f62270e0a35bBf0756;
        if (assetAddr == kitties) {
            // Cryptokitties.
            // (bool success, bytes memory result) = assetAddr.call(abi.encodeWithSignature("approve(address,uint256)", spender, tokenId));
            (bool success, bytes memory result) = assetAddr.call(abi.encodeWithSelector(0x095ea7b3, spender, tokenId)); // save gas
            require(success && result.length == 0, "approve kitty fail");
        } else if (assetAddr == punks) {
            // // CryptoPunks.
            // (bool checkSuccess, bytes memory ownerResult) = address(assetAddr).staticcall(abi.encodeWithSignature("punkIndexToAddress(uint256)", tokenId));
            (bool checkSuccess, bytes memory ownerResult) = address(assetAddr).staticcall(abi.encodeWithSelector(0x58178168, tokenId)); // save gas
            (address _owner) = abi.decode(ownerResult, (address));
            require(checkSuccess && _owner == owner, "approve punk not owner");
            // (bool success, bytes memory result) = assetAddr.call(abi.encodeWithSignature("offerPunkForSaleToAddress(uint256,uint256,address)", tokenId, 0, spender));
            (bool success, bytes memory result) = assetAddr.call(abi.encodeWithSelector(0xbf31196f, tokenId, 0, spender)); // save gas
            require(success && result.length == 0, "approve punk fail");

        } else if (assetAddr == voxels || assetAddr == makersTokenV2) {
            // (bool success, bytes memory result) = assetAddr.call(abi.encodeWithSignature("approve(address,uint256)", spender, tokenId));
            (bool success, bytes memory result) = assetAddr.call(abi.encodeWithSelector(0x095ea7b3, spender, tokenId)); // save gas
            require(success && result.length == 0, "approve voxels fail");
        } else {
            // Default.
            // (bool checkSuccess, bytes memory approvedResult) = assetAddr.staticcall(abi.encodeWithSignature("isApprovedForAll(address,address)", owner, spender));
            (bool checkSuccess, bytes memory approvedResult) = assetAddr.staticcall(abi.encodeWithSelector(0xe985e9c5, owner, spender)); // save gas
            (bool approvedForAll) = abi.decode(approvedResult, (bool));
            require(checkSuccess, "isAprovedForAll fail");
            if (!approvedForAll) {
                // (bool success, bytes memory result) = assetAddr.call(abi.encodeWithSignature("setApprovalForAll(address,bool)", spender, true));
                (bool success, bytes memory result) = assetAddr.call(abi.encodeWithSelector(0xa22cb465, spender, true)); // save gas
                require(success && result.length == 0, "setApprovalForAll fail");
            }
            
        }

    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IForwardVault is IERC20Upgradeable {
    
    // write methods
    function deposit(uint256 _amount) external returns (uint256 shares);
    function depositAll() external returns (uint256 shares);
    function withdraw(uint256 _shares) external returns (uint256 tokens);
    function withdrawAll() external returns (uint256 tokens); 

    // read methods
    function balance() external view returns (uint256);
    function balanceSavingsInYVault() external view returns (uint256);
    function suitable() external view returns (uint256);
    function getPricePerFullShare() external view returns (uint256);
    function want() external view returns (address);
    function yVault() external view returns (address);
    function governance() external view returns (address);
    
    function version() external returns (string memory);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}