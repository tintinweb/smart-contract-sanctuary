// SPDX-License-Identifier: MIT

//  ______                        _
// (____  \                      | |
//  ____)  ) ___   ____ _____  __| |
// |  __  ( / _ \ / ___) ___ |/ _  |
// | |__)  ) |_| | |   | ____( (_| |
// |______/ \___/|_|   |_____)\____|

//  ______                    _        ___
// (____  \                  | |      / __)             _
//  ____)  ) ____ _____ _____| |  _ _| |__ _____  ___ _| |_
// |  __  ( / ___) ___ (____ | |_/ |_   __|____ |/___|_   _)
// | |__)  ) |   | ____/ ___ |  _ (  | |  / ___ |___ | | |_
// |______/|_|   |_____)_____|_| \_) |_|  \_____(___/   \__)

//  _______ _        _
// (_______) |      | |
//  _      | | _   _| |__
// | |     | || | | |  _ \
// | |_____| || |_| | |_) )
//  \______)\_)____/|____/


pragma solidity 0.8.7;

import "./Ownable.sol";

contract Whitelist is Ownable {

    uint256 public MAX_QUANTITY = 3;
    uint256 public TOTAL_ENTRIES = 0;
    uint256 public MAX_ENTRIES = 6900;

    bool public isApeListActive = true;
    bool public isEarlybirdListActive = true;
    bool public isPublicListActive = false;

    uint256 public EARLYBIRD_WHITELIST_QTY = 4500;

    uint256 public APE_WHITELIST_QTY = 1000; // BAYC & MAYC
    // Any tokens left over from APE_WHITELIST_QTY & EARLYBIRD_WHITELIST_QTY will be allocated
    // to PUBLIC_WHITELIST_QTY

    uint256 public PUBLIC_WHITELIST_QTY = 1400; // To be calculated with APE and Earlybird after whitelists are closed

    // Mappings
    mapping(string => mapping(address => mapping(string => uint256))) public whitelistAddress;

    // Events
    event TakingOrders(string message);
    event NewEntry(address _entry, uint256 entries, uint256 TOTAL_ENTRIES);
    event WhitelistStatus(string _sale_type, bool status);
    event ApeRemainingQty(string _sale_type, uint256 qty);
    event EarlybirdRemainingQty(string _sale_type, uint256 qty);
    event PublicRemainingQty(string _sale_type, uint256 qty);

    function addToWhitelist(
        string calldata _phase,
        string calldata _sale_type,
        address _entry,
        uint256 _quantity,
        string calldata _nonce)
    external onlyOwner {
        require(isWhitelistActive(_sale_type), "NOT_TAKING_RESERVATIONS_AT_THIS_TIME");
        require(_quantity <= MAX_QUANTITY, "QTY_MAX_LIMIT");
        require(TOTAL_ENTRIES + _quantity <= MAX_ENTRIES, "REACHED_CAPACITY");

        // Ensure last entry is equal to the amount of tokens remaining
        if (keccak256(bytes(_sale_type)) == keccak256(bytes("PUBLIC")) && _quantity > PUBLIC_WHITELIST_QTY) {
            require(PUBLIC_WHITELIST_QTY > 0, "RESERVATIONS_FULL");
            _quantity = PUBLIC_WHITELIST_QTY;
        } else if (keccak256(bytes(_sale_type)) == keccak256(bytes("APE")) && _quantity > APE_WHITELIST_QTY) {
            require(APE_WHITELIST_QTY > 0, "RESERVATIONS_FULL");
            _quantity = APE_WHITELIST_QTY;
        }
        require(validateSaleTypeCount(_sale_type, _quantity), "RESERVATIONS_FULL");
        require(whitelistAddress[_phase][_entry][_nonce] == 0, "ADDRESS_ALREADY_ADDED");
        
        whitelistAddress[_phase][_entry][_nonce] = _quantity;
        TOTAL_ENTRIES += _quantity;

        if (keccak256(bytes(_sale_type)) == keccak256(bytes("APE"))) {
            APE_WHITELIST_QTY -= _quantity;
            emit ApeRemainingQty(_sale_type, APE_WHITELIST_QTY);
        } else if (keccak256(bytes(_sale_type)) == keccak256(bytes("EARLYBIRD"))) {
            EARLYBIRD_WHITELIST_QTY -= _quantity;
            emit EarlybirdRemainingQty(_sale_type, EARLYBIRD_WHITELIST_QTY);
        } else if (keccak256(bytes(_sale_type)) == keccak256(bytes("PUBLIC"))) {
            PUBLIC_WHITELIST_QTY -= _quantity;
            emit PublicRemainingQty(_sale_type, PUBLIC_WHITELIST_QTY);
        }

        emit NewEntry(_entry, _quantity, TOTAL_ENTRIES);
    }

    function validateSaleTypeCount(string calldata _sale_type, uint256 _quantity) private view returns (bool) {
        if (keccak256(bytes(_sale_type)) == keccak256(bytes("APE"))) {
            return !(_quantity > APE_WHITELIST_QTY);
        } else if (keccak256(bytes(_sale_type)) == keccak256(bytes("EARLYBIRD"))) {
            return !(_quantity > EARLYBIRD_WHITELIST_QTY);
        } else if (keccak256(bytes(_sale_type)) == keccak256(bytes("PUBLIC"))) {
            return !(_quantity > PUBLIC_WHITELIST_QTY);
        } else {
            return false;
        }
    }

    function isWhitelistActive(string calldata _sale_type) private view returns (bool) {
        if (keccak256(bytes(_sale_type)) == keccak256(bytes("APE"))) {
            return isApeListActive;
        } else if (keccak256(bytes(_sale_type)) == keccak256(bytes("EARLYBIRD"))) {
            return isEarlybirdListActive;
        } else if (keccak256(bytes(_sale_type)) == keccak256(bytes("PUBLIC"))) {
            return isPublicListActive;
        } else {
            return false;
        }
    }

    // Setters

    function setApeListStatus() external onlyOwner {
        isApeListActive = !isApeListActive;
        emit WhitelistStatus("APE", isApeListActive);
    }

    function setEarlybirdListStatus() external onlyOwner {
        isEarlybirdListActive = !isEarlybirdListActive;
        emit WhitelistStatus("EARLYBIRD", isEarlybirdListActive);
    }

    function setPublicListStatus() external onlyOwner {
        isPublicListActive = !isPublicListActive;
        emit WhitelistStatus("PUBLIC", isPublicListActive);
    }

    function setApeWhitelist(uint256 _max_entries) external onlyOwner {
        APE_WHITELIST_QTY = _max_entries;
    }

    function setEarlybirdWhitelist(uint256 _max_entries) external onlyOwner {
        EARLYBIRD_WHITELIST_QTY = _max_entries;
    }

    function setPublicWhitelist(uint256 _max_entries) external onlyOwner {
        PUBLIC_WHITELIST_QTY = _max_entries;
    }

    function setPublicWhitelistFinal() external onlyOwner {
        isEarlybirdListActive = false;
        isApeListActive = false;
        PUBLIC_WHITELIST_QTY = PUBLIC_WHITELIST_QTY + APE_WHITELIST_QTY + EARLYBIRD_WHITELIST_QTY;
        APE_WHITELIST_QTY = 0;
        EARLYBIRD_WHITELIST_QTY = 0;
    }

    function setMaxQuantity(uint256 _max_quantity) external onlyOwner {
        MAX_QUANTITY = _max_quantity;
    }

    function resetEntries() external onlyOwner {
        TOTAL_ENTRIES = 0;
    }
}