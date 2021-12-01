// SPDX-License-Identifier: NONE

import "./ierc20.sol";

pragma solidity ^0.8.0;

contract SWAP {
    event OffersChanged();
    event NewTrade(uint256 timestamp, uint256 amountToken, uint256 amountOtherToken);
    
    // Ein Offer wie es im Storage gespeichert wird
    struct Offer {
        uint256 quantity;
        uint256 price;
        bool bid;
        address offererAddress;
    }
    
    // Ein Offer wie es von der read-only Funktion zurückgegeben wird
    struct OfferDetails {
        uint256 quantity;
        uint256 price;
        bool bid;
        address offererAddress;
        // Ist das Offer valid (Counterpart allowance und funds)
        bool valid;
        uint8 id;
    }
    
    // Ein Trade (für die Trade History)
    struct Trade {
        uint256 timestamp;
        uint256 amountToken;
        uint256 amountOtherToken;
    }

    string private _name;
    address _token;
    address _otherToken;
    // Decimals von token2
    uint8 decimals1;
    uint8 decimals2;
    
    mapping(uint8 => Offer) offers;
    mapping(uint8 => bool) usedSlots;
    Trade[] tradeHistory;
    uint8 private _offerCount = 0;
    
    
    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(address token, address otherToken) {
        // Variablen eintragen
        _token = token;
        _otherToken = otherToken;
        // Namen der Token holen und speichern
        IERC20 token1 = IERC20(_token);
        IERC20 token2 = IERC20(_otherToken);
        _name = append(token1.name(), "<->",token2.name());
        decimals1 = token1.decimals();
        decimals2 = token2.decimals();
    }

    // Gibt den Namen vom Contract zurück (beide Tokens)
    function name() public view returns (string memory) {
        return _name;
    }
    
    function tokens() public view returns (address, address) {
        return (_token, _otherToken);
    }
    
    // Testet ob ein Offer valide ist und angenommen werden kann (genug funds und allowance auf beiden Seiten)
    function checkOffer(uint8 id, uint256 quantity) public view returns (bool,string memory) {
        // Instanzen der beiden Tokens erzeugen
        IERC20 token1 = IERC20(_token);
        IERC20 token2 = IERC20(_otherToken);
        // Offer holen
        Offer memory offer = offers[id];
        // Quantity darf nicht höher sein als die vom offer
        if (offer.quantity < quantity) return (false, "Too much quantity");
        uint256 amountToken = quantity;
        // Betrag in other Token = quantity * price (Decimals beachten!!!)
        uint256 amountOtherToken = (quantity *offer.price)/10**decimals1;
        // Ein Verkaufsangebot wird angenommen 
        //  msg.sender gibt otherToken * price - Counterpart gibt token
        if (offer.bid == false) {
            // Funds und Allowance muss beimn msg.sender vorhanden sein
            if (token2.balanceOf(msg.sender) < amountOtherToken) return (false, "ASK: Not enough funds at msg.sender");
            if (token2.allowance(msg.sender, address(this)) < amountOtherToken) return (false, "ASK: Not enough allowance at msg.sender");
            // Genauso auch beim Counterpart
            (bool result, string memory reason) = checkOfferCounterpart(id, amountToken);
            if (result == false) return (result, reason);
            // alles OK
            return (true, "OK");
        } else {
            // Ein Kaufangebot wird angenommen 
            // msg.sender verkauft, counterpart kauft (BID)
            // msg.sender gibt token2 quantity * price, counterpart gibt token1
            // Funds und Allowance muss beimn Sender vorhanden sein
            if (token1.balanceOf(msg.sender) < amountToken) return (false, "BID: Not enough funds at msg.sender");
            if (token1.allowance(msg.sender, address(this)) < amountToken) return (false, "BID: Not enough allowance at msg.sender");
            // Genauso auch beim Counterpart
            (bool result, string memory reason) = checkOfferCounterpart(id, amountToken);
            if (result == false) return (result, reason);
            // alles OK
            return (true,"OK");
        }
    }
    
    function checkOfferCounterpart(uint8 id, uint256 quantity) public view returns (bool, string memory) {
        // Instanzen der beiden Tokens erzeugen
        IERC20 token1 = IERC20(_token);
        IERC20 token2 = IERC20(_otherToken);
        // Offer holen
        Offer memory offer = offers[id];
        address counterpart = offer.offererAddress;
        // amountToken = Quantity vom Offer (wenn 0 als quanitty übergeben wurde)
        uint256 amountToken;
        // Wenn 0 als quantity übergeben wurde => die volle Quantity des Offers checken
        if (quantity == 0) amountToken = offer.quantity;
        // Ansonsten übergebene Quantity
        else amountToken = quantity;
        // Betrag in other Token = quantity * price (Decimals beachten!!!)
        uint256 amountOtherToken = (quantity * offer.price)/(10**decimals1);
        // Ein Verkaufsangebot - ASK
        // Counterpart bietet token für otherToken
        if (offer.bid == false) {
            if (token1.balanceOf(counterpart) < amountToken) return (false, "ASK: Not enough funds at counterpart");
            if (token1.allowance(counterpart, address(this)) < amountToken) return (false, "ASK: Not enough allowance at counterpart" );
            // alles OK
            return (true, "OK");
        } else {
            // Ein Kaufangebot - BID 
            // Counterpart bietet otherToken für Token
            // Funds und Allowance muss beimn Counterpart vorhanden sein
            if (token2.balanceOf(counterpart) < amountOtherToken) return (false, "BID: Not enough funds at counterpart");
            if (token2.allowance(counterpart, address(this)) < amountOtherToken) return (false, "BID: Not enough allowance at counterpart" );
            // alles OK
            return (true,"OK");
        }
        
    }

    // Tragt ein neues Offer in die Datenbank ein
    function addOffer(uint256 quantity, uint256 price, bool bid) public {
        // Approval
        // Kaufangebot (Verkauf von quantity x price von otherToken)
        if (bid == true) {
            IERC20 token2 = IERC20(_otherToken);
            uint256 amount = quantity * price / 10**decimals1;
            // Allowance und balance_of muss ausreichend vorhanden sein
            require(token2.balanceOf(msg.sender) >= amount, "Not enough funds");
            //require(token2.allowance(msg.sender, address(this)) >= amount, "Not enough allowance");
        } else {
        // Verkaufangebot (Kauf von otherToken)
            IERC20 token1 = IERC20(_token);
            uint256 amount = quantity;
            // Balance und Allowance muss ausreichend vorhanden sein
            require(token1.balanceOf(msg.sender) >= amount, "Not enough funds");
            //require(token2.allowance(msg.sender, address(this)) >= amount, "Not enough allowance");
        }
        
        // Neues Offer Objekt erstellen
        Offer memory newOffer;
        newOffer.quantity = quantity;
        newOffer.price = price;
        newOffer.bid = bid;
        newOffer.offererAddress = msg.sender;
        // In Storage schreiben
        uint8 slot = firstFreeSlot();
        offers[slot] = newOffer;
        usedSlots[slot] = true;
        _offerCount++;
        // Event auslösen
        emit OffersChanged();
    }
    
    function acceptOffer(uint8 id, uint256 quantity) public {
        // Instanzen der beiden Tokens erzeugen
        IERC20 token1 = IERC20(_token);
        IERC20 token2 = IERC20(_otherToken);
        // Offer holen
        Offer memory offer = offers[id];
        

        // Quantity darf nicht höher sein als die vom offer
        require(offer.quantity >= quantity, "Too much quantity");
        address counterpart = offer.offererAddress;
        uint256 amountToken = quantity;
        // Betrag in other Token = quantity * price (Decimals beachten!!!)
        uint256 amountOtherToken = (quantity * offer.price)/(10**decimals1);
        /*
        // Ein Verkaufsangebot wird angenommen 
        //  msg.sender gibt token1 - Counterpart gibt token2 quantity * price
        if (offer.bid == false) {
            // Funds und Allowance muss beimn msg.sender vorhanden sein
            require (token2.balanceOf(msg.sender) >= amountOtherToken, "ASK: Not enough funds at msg.sender");
            require (token2.allowance(msg.sender, address(this)) >= amountOtherToken, "ASK: Not enough allowance at msg.sender" );
            // Genauso auch beim Counterpart
            require (token1.balanceOf(counterpart) >= amountToken, "ASK: Not enough funds at counterpart");
            require (token1.allowance(counterpart, address(this)) >= amountToken, "ASK: Not enough allowance at counterpart" );
            // Tausch durchführen
            token2.transferFrom(msg.sender, counterpart, amountOtherToken);
            token1.transferFrom(counterpart, msg.sender, amountToken);
        } else {
            // Ein Kaufangebot wird angenommen 
            // msg.sender kauft, counterpart verkauft
            // msg.sender gibt token2 quantity * price, counterpart gibt token1
            // Funds und Allowance muss beimn Counterpart vorhanden sein
            require (token1.balanceOf(msg.sender) >= amountToken, "BID: Not enough funds at msg.sender");
            require (token1.allowance(msg.sender, address(this)) >= amountToken, "BID: Not enough allowance at msg.sender" );
            // Genauso auch beim msg.sender
            require (token2.balanceOf(counterpart) >= amountOtherToken, "BID: Not enough funds at counterpart");
            require (token2.allowance(counterpart, address(this)) >= amountOtherToken, "BID: Not enough allowance at counterpart" );
        }
        */
        (bool result, string memory reason) = checkOffer(id, quantity);
        require(result == true, reason);

        // bid = false im Angebot, price=ask, Ein Verkaufsangebot wird angenommen 
        //  msg.sender gibt token2 quantity * price - Counterpart gibt token1
        if (offer.bid == false) {
            // Tausch durchführen
            require(token2.transferFrom(msg.sender, counterpart, amountOtherToken), "Transfer of token2 failed");
            require(token1.transferFrom(counterpart, msg.sender, amountToken), "Transfer of token1 failed");
        // bid = true im Angebot, Ein Kaufangebot wird angenommen 
        // msg.sender gibt token1, counterpart gibt token2 quantity * price
        } else {
            require(token1.transferFrom(msg.sender, counterpart, amountToken), "Transfer of token1 failed");
            require(token2.transferFrom(counterpart, msg.sender, amountOtherToken), "Transfer of token2 failed");
        }
        
        // Offer um Quantity reduzieren bzw. canceln wenn diese 0 ist
        offer.quantity -= quantity;
        if (offer.quantity == 0) cancelOffer(id);
        // Offer in Storage speichern
        offers[id] = offer;
        // Trade in Tradehistory (Storage) speichern
        tradeHistory.push(Trade(block.timestamp, amountToken, amountOtherToken));
        // Events auslösen
        emit OffersChanged();
        emit NewTrade(block.timestamp, amountToken, amountOtherToken);
    }
    
    // Entfernt ein Offer aus dem Storage
    function cancelOffer(uint8 id) public {
        delete(offers[id]);
        usedSlots[id] = false;
        _offerCount--;
        // Event auslösen
        emit OffersChanged();
    }
    
    // Read Only Methoden
    // Zeigt die Allowances für die beiden Token und die aufrufende Addresse
    function allowances() public view returns (uint256, uint256) {
        IERC20 token1 = IERC20(_token);
        IERC20 token2 = IERC20(_otherToken);
        return (token1.allowance(msg.sender, address(this)), token2.allowance(msg.sender, address(this)));
    }
     
    // Gibt den ersten freien Slot für ein Offer zurück (im mapping)
    function firstFreeSlot() public view returns (uint8 index) {
        for (uint8 t = 0; t < 255; t++) {
            if (usedSlots[t] == false) return t;
        }
    }
    
    // Gibt die Anzahl der Offers zurück
    function offerCount() public view returns (uint8) {
        return _offerCount;
        /*
        uint8 result = 0;
        for (uint8 t = 0; t < 255; t++) {
            if (usedSlots[t] == true) result++;
        }
        return result;
        */
    }

    // Gibt alle Offers zurück    
    function showOffers() public view returns (OfferDetails[] memory) {
        // Counter für Ziel-Array
        uint8 cnt = 0;
        // Counter für alle Offers
        uint8 cnt2 = 0;
        // Ziel Array anlegen
        OfferDetails[] memory result = new OfferDetails[](_offerCount);
        // Wenn keine Offers => leeres Array zurückgegeben
        if (_offerCount == 0) return result;
        // Alle Slots durchgehen und gültige Angebote zeigen
        for (uint8 t = 0; t < 255; t++) {
            // Checken ob Offer gültig ist (Counterpart funds und allowance)
            (bool check,) = checkOfferCounterpart(t,0);
            if (usedSlots[t] == true) {
                OfferDetails memory details;
                details.quantity = offers[t].quantity;
                details.price = offers[t].price;
                details.bid = offers[t].bid;
                details.offererAddress = offers[t].offererAddress;
                details.id = t;
                details.valid = check;
                result[cnt] = details;
                cnt++;
            }
            cnt2++;
            if (cnt2 == _offerCount) return result;
        }
        return result;
    }
    
    // Zeigt die Tradehistory an
    function showTradeHistory() public view returns (Trade[] memory) {
        return tradeHistory;
    }

    // String concat function
    function append(string memory a, string memory b, string memory c) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b, c));
    }
   
}