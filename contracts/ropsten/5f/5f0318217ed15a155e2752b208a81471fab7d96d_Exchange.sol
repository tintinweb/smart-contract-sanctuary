pragma solidity ^0.4.23;

contract Exchange {

    event AssetAssign(uint id, address user, address emitter, string data);
    event AssetBurn(uint id);
    event AssetMove(uint id, address from, address to);
    event AssetClaimStringSet(uint id, string claim_code);
    event NewTradeOffer(uint id, address sender, address receiver, uint[] my_items, uint[] their_items);
    event ModifyTradeOffer(uint id, TradeOfferState state);

    constructor() public {
        assets.push(Asset(0, 0, "", ""));
        uint[] memory my_items;
        uint[] memory their_items;
        offers.push(TradeOffer(0, 0, my_items, their_items, TradeOfferState.CANCELLED));
    }

    enum TradeOfferState {
        PENDING,
        CANCELLED,
        ACCEPTED,
        DECLINED
    }

    struct Asset {
        address emitter;
        address owner;
        string data;
        string claim_string;
    }

    struct TradeOffer {
        address sender;
        address recipient;
        uint[] my_items;
        uint[] their_items;
        TradeOfferState state;
    }

    struct User {
        uint[] owned_assets;
        uint pending_offer_id;
    }

    TradeOffer[] offers;
    Asset[] assets;

    mapping(address => User) users;

    // gives a new asset with _data string to _user
    // asset_emitter equals msg.sender
    function assign(address _owner, string _data) external {
        assets.push(Asset(msg.sender, _owner, _data, ""));
        users[_owner].owned_assets.push(assets.length - 1);
        emit AssetAssign(assets.length - 1, _owner, msg.sender, _data);
    }
    
    // burns the asset with given id or throws IF:
    // - the asset emitter is not msg.sender
    // - the asset with said id does not exist
    function burn(uint _id) external {

        require(assets[_id].emitter == msg.sender, "In order to burn an asset, you need to be the one who emitted it.");
        
        removeUserAsset(assets[_id].owner, _id);

        delete assets[_id];
        emit AssetBurn(_id);

    }

    function removeUserAsset(address _user, uint _id) internal {

        uint index = users[_user].owned_assets.length;
        
        for(uint i = 0; i < users[_user].owned_assets.length; i++) {
            if(users[_user].owned_assets[i] == _id) {
                index = i;
                break;
            }
        }

        if (index >= users[_user].owned_assets.length) return;

        for (i = index; i < users[_user].owned_assets.length-1; i++){
            users[_user].owned_assets[i] = users[_user].owned_assets[i+1];
        }
        users[_user].owned_assets.length--;
    }

    function getAssetEmmiter(uint _id) external view returns (address) {
        return assets[_id].emitter;
    }

    function getAssetOwner(uint _id) external view returns (address) {
        return assets[_id].owner;
    }

    function getAssetData(uint _id) external view returns (string) {
        return assets[_id].data;
    }

    // should make a new trade offer or throw IF:
    // - sender address does not have an item listen in _my_items
    // - partner address does not have an item listen in _their_items
    // - you have a pending trade offer

    function sendTradeOffer(address _partner, uint[] _my_items, uint[] _their_items) external returns (uint) {
        require(users[msg.sender].pending_offer_id == 0, "You already have one trade offer. Cancel it first to make a new one.");
        for(uint i = 0; i < _my_items.length; i++) {
            require(assets[_my_items[i]].owner == msg.sender, "You attempted to trade item(s) which you do not own.");
        }
        for(i = 0; i < _their_items.length; i++) {
            require(assets[_their_items[i]].owner == _partner, "You attempted to request item(s) which your partner does not own.");
        }
        offers.push(TradeOffer(msg.sender, _partner, _my_items, _their_items, TradeOfferState.PENDING));
        users[msg.sender].pending_offer_id = offers.length - 1;
        emit NewTradeOffer(offers.length - 1, msg.sender, _partner, _my_items, _their_items);
        return offers.length - 1;
    }

    // should cancel pending trade offer or throw IF:
    // - sender has no pending tradeoffer
    function cancelTradeOffer() external {
        require(users[msg.sender].pending_offer_id != 0, "You have no pending trade offer.");
        offers[users[msg.sender].pending_offer_id].state = TradeOfferState.CANCELLED;
        emit ModifyTradeOffer(users[msg.sender].pending_offer_id, TradeOfferState.CANCELLED);
        users[msg.sender].pending_offer_id = 0;
    }

    // should make the magic (exchange the items) or throw IF:
    // - offer_recipient is not sender
    // - items do not exist anymore in either inventories
    // - offer must be PENDING
    function acceptTradeOffer(uint _offer_id) external {
        require(offers[_offer_id].recipient == msg.sender, "You are not the recipient of given trade offer.");
        require(offers[_offer_id].state == TradeOfferState.PENDING, "This offer is not pending.");
        for(uint i = 0; i < offers[_offer_id].my_items.length; i++) {
            require(assets[offers[_offer_id].my_items[i]].owner == offers[_offer_id].sender, "Offer sender no longer owns mentioned items.");
        }
        for(i = 0; i < offers[_offer_id].their_items.length; i++) {
            require(assets[offers[_offer_id].their_items[i]].owner == msg.sender, "You no longer own mentioned items.");
        }
        for(i = 0; i < offers[_offer_id].my_items.length; i++) {
            setAssetOwner(offers[_offer_id].my_items[i], msg.sender);
        }
        for(i = 0; i < offers[_offer_id].their_items.length; i++) {
            setAssetOwner(offers[_offer_id].their_items[i], offers[_offer_id].sender);
        }
        offers[_offer_id].state = TradeOfferState.ACCEPTED;
        users[offers[_offer_id].sender].pending_offer_id = 0;
        emit ModifyTradeOffer(_offer_id, TradeOfferState.ACCEPTED);
    }

    function setAssetOwner(uint _id, address _new_owner) internal {
        emit AssetMove(_id, assets[_id].owner, _new_owner);
        removeUserAsset(assets[_id].owner, _id);
        assets[_id].owner = _new_owner;
        assets[_id].claim_string = "";
        users[_new_owner].owned_assets.push(_id);
    }

    // should decline pending trade offer or throw IF:
    // - _offer_id does not exist
    // - offer&#39;s recipient is not msg.sender
    // - offer is not PENDING
    function declineTradeOffer(uint _offer_id) external {
        require(offers[_offer_id].recipient == msg.sender, "You are not the recipient of given trade offer.");
        require(offers[_offer_id].state == TradeOfferState.PENDING, "This offer is not pending.");
        offers[_offer_id].state = TradeOfferState.DECLINED;
        users[offers[_offer_id].sender].pending_offer_id = 0;
        emit ModifyTradeOffer(_offer_id, TradeOfferState.DECLINED);
    }

    // set item claim string or throw IF:
    // - msg.sender is not asset owner
    function setAssetClaimString(uint _id, string _claim_string) external {
        require(assets[_id].owner == msg.sender, "Only asset owner can set a claim string.");
        assets[_id].claim_string = _claim_string;
        emit AssetClaimStringSet(_id, _claim_string);
    }

    function getUserInventory(address _address) external view returns (uint[]) {
        return users[_address].owned_assets;
    }

    function getMyInventory() external view returns (uint[]) {
        return users[msg.sender].owned_assets;
    }

    function getAssetClaimString(uint _id) external view returns (string) {
        return assets[_id].claim_string;
    }
}