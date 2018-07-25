pragma solidity 0.4.24;

// File: contracts/ds-auth/auth.sol

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity 0.4.24;

contract DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) public view returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        public
        auth
    {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
        public
        auth
    {
        authority = authority_;
        emit LogSetAuthority(authority);
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig));
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, this, sig);
        }
    }
}

// File: contracts/AssetPriceOracle.sol

contract AssetPriceOracle is DSAuth {
    // Maximum value expressible with uint128 is 340282366920938463463374607431768211456.
    // Using 18 decimals for price records (standard Ether precision), 
    // the possible values are between 0 and 340282366920938463463.374607431768211456.

    struct AssetPriceRecord {
        uint128 price;
        bool isRecord;
    }

    mapping(uint128 => mapping(uint128 => AssetPriceRecord)) public assetPriceRecords;

    event AssetPriceRecorded(
        uint128 indexed assetId,
        uint128 indexed blockNumber,
        uint128 indexed price
    );

    constructor() public {
    }
    
    function recordAssetPrice(uint128 assetId, uint128 blockNumber, uint128 price) public auth {
        assetPriceRecords[assetId][blockNumber].price = price;
        assetPriceRecords[assetId][blockNumber].isRecord = true;
        emit AssetPriceRecorded(assetId, blockNumber, price);
    }

    function getAssetPrice(uint128 assetId, uint128 blockNumber) public view returns (uint128 price) {
        AssetPriceRecord storage priceRecord = assetPriceRecords[assetId][blockNumber];
        require(priceRecord.isRecord);
        return priceRecord.price;
    }

    function () public {
        // dont receive ether via fallback method (by not having &#39;payable&#39; modifier on this function).
    }
}

// File: contracts/lib/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 * Source: https://github.com/facuspagnuolo/zeppelin-solidity/blob/feature/705_add_safe_math_int_ops/contracts/math/SafeMath.sol
 */
library SafeMath {

  /**
  * @dev Multiplies two unsigned integers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Multiplies two signed integers, throws on overflow.
  */
  function mul(int256 a, int256 b) internal pure returns (int256) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }
    int256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two unsigned integers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Integer division of two signed integers, truncating the quotient.
  */
  function div(int256 a, int256 b) internal pure returns (int256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // Overflow only happens when the smallest negative int is multiplied by -1.
    int256 INT256_MIN = int256((uint256(1) << 255));
    assert(a != INT256_MIN || b != -1);
    return a / b;
  }

  /**
  * @dev Subtracts two unsigned integers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Subtracts two signed integers, throws on overflow.
  */
  function sub(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a - b;
    assert((b >= 0 && c <= a) || (b < 0 && c > a));
    return c;
  }

  /**
  * @dev Adds two unsigned integers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }

  /**
  * @dev Adds two signed integers, throws on overflow.
  */
  function add(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a + b;
    assert((b >= 0 && c >= a) || (b < 0 && c < a));
    return c;
  }
}

// File: contracts/ContractForDifference.sol

contract ContractForDifference is DSAuth {
    using SafeMath for int256;

    enum Position { Long, Short }
    
    /**
     * A party to the contract. Either the maker or the taker.
     */
    struct Party {
        address addr;
        uint128 withdrawBalance; // Amount the Party can withdraw, as a result of settled contract.
        Position position;
        bool isPaid;
    }
    
    struct Cfd {
        Party maker;
        Party taker;

        uint128 assetId;
        uint128 amount; // in Wei.
        uint128 contractStartBlock; // Block number
        uint128 contractEndBlock; // Block number

        // CFD state variables
        bool isTaken;
        bool isSettled;
        bool isRefunded;
    }

    uint128 public leverage = 1; // Global leverage of the CFD contract.
    AssetPriceOracle public priceOracle;

    mapping(uint128 => Cfd) public contracts;
    uint128                 public numberOfContracts;

    event LogMakeCfd (
    uint128 indexed cfdId, 
    address indexed makerAddress, 
    Position indexed makerPosition,
    uint128 assetId,
    uint128 amount,
    uint128 contractEndBlock);

    event LogTakeCfd (
    uint128 indexed cfdId,
    address indexed makerAddress,
    Position makerPosition,
    address indexed takerAddress,
    Position takerPosition,
    uint128 assetId,
    uint128 amount,
    uint128 contractStartBlock,
    uint128 contractEndBlock);

    event LogCfdSettled (
    uint128 indexed cfdId,
    address indexed makerAddress,
    address indexed takerAddress,
    uint128 amount,
    uint128 startPrice,
    uint128 endPrice,
    uint128 makerSettlement,
    uint128 takerSettlement);

    event LogCfdRefunded (
    uint128 indexed cfdId,
    address indexed makerAddress,
    uint128 amount);

    event LogCfdForceRefunded (
    uint128 indexed cfdId,
    address indexed makerAddress,
    uint128 makerAmount,
    address indexed takerAddress,
    uint128 takerAmount);

    event LogWithdrawal (
    uint128 indexed cfdId,
    address indexed withdrawalAddress,
    uint128 amount);

    // event Debug (
    //     string description,
    //     uint128 uintValue,
    //     int128 intValue
    // );

    constructor(address priceOracleAddress) public {
        priceOracle = AssetPriceOracle(priceOracleAddress);
    }

    function makeCfd(
        address makerAddress,
        uint128 assetId,
        Position makerPosition,
        uint128 contractEndBlock
        )
        public
        payable
        returns (uint128)
    {
        require(contractEndBlock > block.number); // Contract end block must be after current block.
        require(msg.value > 0); // Contract Wei amount must be more than zero - contracts for zero Wei does not make sense.
        require(makerAddress != address(0)); // Maker must provide a non-zero address.
        
        uint128 contractId = numberOfContracts;

        /**
         * Initialize CFD struct using tight variable packing pattern.
         * See https://fravoll.github.io/solidity-patterns/tight_variable_packing.html
         */
        Party memory maker = Party(makerAddress, 0, makerPosition, false);
        Party memory taker = Party(address(0), 0, Position.Long, false);
        Cfd memory newCfd = Cfd(
            maker,
            taker,
            assetId,
            uint128(msg.value),
            0,
            contractEndBlock,
            false,
            false,
            false
        );

        contracts[contractId] = newCfd;

        // contracts[contractId].maker.addr = makerAddress;
        // contracts[contractId].maker.position = makerPosition;
        // contracts[contractId].assetId = assetId;
        // contracts[contractId].amount = uint128(msg.value);
        // contracts[contractId].contractEndBlock = contractEndBlock;

        numberOfContracts++;
        
        emit LogMakeCfd(
            contractId,
            contracts[contractId].maker.addr,
            contracts[contractId].maker.position,
            contracts[contractId].assetId,
            contracts[contractId].amount,
            contracts[contractId].contractEndBlock
        );

        return contractId;
    }

    function getCfd(
        uint128 cfdId
        ) 
        public 
        view 
        returns (address makerAddress, Position makerPosition, address takerAddress, Position takerPosition, uint128 assetId, uint128 amount, uint128 startTime, uint128 endTime, bool isTaken, bool isSettled, bool isRefunded)
        {
        Cfd storage cfd = contracts[cfdId];
        return (
            cfd.maker.addr,
            cfd.maker.position,
            cfd.taker.addr,
            cfd.taker.position,
            cfd.assetId,
            cfd.amount,
            cfd.contractStartBlock,
            cfd.contractEndBlock,
            cfd.isTaken,
            cfd.isSettled,
            cfd.isRefunded
        );
    }

    function takeCfd(
        uint128 cfdId, 
        address takerAddress
        ) 
        public
        payable
        returns (bool success) {
        Cfd storage cfd = contracts[cfdId];
        
        require(cfd.isTaken != true);                  // Contract must not be taken.
        require(cfd.isSettled != true);                // Contract must not be settled.
        require(cfd.isRefunded != true);               // Contract must not be refunded.
        require(cfd.maker.addr != address(0));         // Contract must have a maker,
        require(cfd.taker.addr == address(0));         // and no taker.
        // require(takerAddress != cfd.maker.addr);       // Maker and Taker must not be the same address. (disabled for now)
        require(msg.value == cfd.amount);              // Takers deposit must match makers deposit.
        require(takerAddress != address(0));           // Taker must provide a non-zero address.
        require(block.number <= cfd.contractEndBlock); // Taker must take contract before end block.

        cfd.taker.addr = takerAddress;
        // Make taker position the inverse of maker position
        cfd.taker.position = cfd.maker.position == Position.Long ? Position.Short : Position.Long;
        cfd.contractStartBlock = uint128(block.number);
        cfd.isTaken = true;

        emit LogTakeCfd(
            cfdId,
            cfd.maker.addr,
            cfd.maker.position,
            cfd.taker.addr,
            cfd.taker.position,
            cfd.assetId,
            cfd.amount,
            cfd.contractStartBlock,
            cfd.contractEndBlock
        );
            
        return true;
    }

    function settleAndWithdrawCfd(
        uint128 cfdId
        )
        public {
        address makerAddr = contracts[cfdId].maker.addr;
        address takerAddr = contracts[cfdId].taker.addr;

        settleCfd(cfdId);
        withdraw(cfdId, makerAddr);
        withdraw(cfdId, takerAddr);
    }

    function settleCfd(
        uint128 cfdId
        )
        public
        returns (bool success) {
        Cfd storage cfd = contracts[cfdId];

        require(cfd.contractEndBlock <= block.number); // Contract must have met its end time.
        require(!cfd.isSettled);                       // Contract must not be settled already.
        require(!cfd.isRefunded);                      // Contract must not be refunded.
        require(cfd.isTaken);                          // Contract must be taken.
        require(cfd.maker.addr != address(0));         // Contract must have a maker address.
        require(cfd.taker.addr != address(0));         // Contract must have a taker address.

        // Get relevant variables
        uint128 amount = cfd.amount;
        uint128 startPrice = priceOracle.getAssetPrice(cfd.assetId, cfd.contractStartBlock);
        uint128 endPrice = priceOracle.getAssetPrice(cfd.assetId, cfd.contractEndBlock);

        /**
         * Register settlements for maker and taker.
         * Maker recieves any leftover wei from integer division.
         */
        uint128 takerSettlement = getSettlementAmount(amount, startPrice, endPrice, cfd.taker.position);
        if (takerSettlement > 0) {
            cfd.taker.withdrawBalance = takerSettlement;
        }

        uint128 makerSettlement = (amount * 2) - takerSettlement;
        cfd.maker.withdrawBalance = makerSettlement;

        // Mark contract as settled.
        cfd.isSettled = true;

        emit LogCfdSettled (
            cfdId,
            cfd.maker.addr,
            cfd.taker.addr,
            amount,
            startPrice,
            endPrice,
            makerSettlement,
            takerSettlement
        );

        return true;
    }

    function withdraw(
        uint128 cfdId, 
        address partyAddress
    )
    public {
        Cfd storage cfd = contracts[cfdId];
        Party storage party = partyAddress == cfd.maker.addr ? cfd.maker : cfd.taker;
        require(party.withdrawBalance > 0); // The party must have a withdraw balance from previous settlement.
        require(!party.isPaid); // The party must have already been paid out, fx from a refund.
        
        uint128 amount = party.withdrawBalance;
        party.withdrawBalance = 0;
        party.isPaid = true;
        
        party.addr.transfer(amount);

        emit LogWithdrawal(
            cfdId,
            party.addr,
            amount
        );
    }

    function getSettlementAmount(
        uint128 amountUInt,
        uint128 entryPriceUInt,
        uint128 exitPriceUInt,
        Position position
    )
    public
    view
    returns (uint128) {
        require(position == Position.Long || position == Position.Short);

        // If price didn&#39;t change, settle for equal amount to long and short.
        if (entryPriceUInt == exitPriceUInt) {return amountUInt;}

        // If entry price is 0 and exit price is more than 0, all must go to long position and nothing to short.
        if (entryPriceUInt == 0 && exitPriceUInt > 0) {
            return position == Position.Long ? amountUInt * 2 : 0;
        }

        // Cast uint128 to int256 to support negative numbers and increase over- and underflow limits
        int256 entryPrice = int256(entryPriceUInt);
        int256 exitPrice = int256(exitPriceUInt);
        int256 amount = int256(amountUInt);

        // Price diff calc depends on which position we are calculating settlement for.
        int256 priceDiff = position == Position.Long ? exitPrice.sub(entryPrice) : entryPrice.sub(exitPrice);
        int256 settlement = amount.add(priceDiff.mul(amount).mul(leverage).div(entryPrice));
        if (settlement < 0) {
            return 0; // Calculated settlement was negative. But a party can&#39;t lose more than his deposit, so he&#39;s just awarded 0.
        } else if (settlement > amount * 2) {
            return amountUInt * 2; // Calculated settlement was more than the total deposits, so settle for the total deposits.
        } else {
            return uint128(settlement); // Settlement was more than zero and less than sum of deposit amounts, so we can settle it as is.
        }
    }

    function refundCfd(
        uint128 cfdId
    )
    public
    returns (bool success) {
        Cfd storage cfd = contracts[cfdId];
        require(!cfd.isSettled);                // Contract must not be settled already.
        require(!cfd.isTaken);                  // Contract must not be taken.
        require(!cfd.isRefunded);               // Contract must not be refunded already.
        require(msg.sender == cfd.maker.addr);  // Function caller must be the contract maker.

        cfd.isRefunded = true;
        cfd.maker.isPaid = true;
        cfd.maker.addr.transfer(cfd.amount);

        emit LogCfdRefunded(
            cfdId,
            cfd.maker.addr,
            cfd.amount
        );

        return true;
    }

    function forceRefundCfd(
        uint128 cfdId
    )
    public
    auth
    {
        Cfd storage cfd = contracts[cfdId];
        require(!cfd.isRefunded); // Contract must not be refunded already.

        cfd.isRefunded = true;

        // Refund Taker
        uint128 takerAmount = 0;
        if (cfd.taker.addr != address(0)) {
            takerAmount = cfd.amount;
            cfd.taker.withdrawBalance = 0; // Refunding must reset withdraw balance, if any.
            cfd.taker.addr.transfer(cfd.amount);
        }

        // Refund Maker
        cfd.maker.withdrawBalance = 0; // Refunding must reset withdraw balance, if any.
        cfd.maker.addr.transfer(cfd.amount);
        
        emit LogCfdForceRefunded(
            cfdId,
            cfd.maker.addr,
            cfd.amount,
            cfd.taker.addr,
            takerAmount
        );
    } 

    function () public {
        // dont receive ether via fallback method (by not having &#39;payable&#39; modifier on this function).
    }
}