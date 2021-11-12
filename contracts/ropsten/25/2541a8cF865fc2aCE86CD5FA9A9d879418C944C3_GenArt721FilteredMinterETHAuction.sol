import "./libs/SafeMath.sol";
import "./libs/Strings.sol";

import "./interfaces/IGenArt721CoreContract.sol";
import "./interfaces/IMinterFilter.sol";

pragma solidity ^0.5.0;

contract GenArt721FilteredMinterETHAuction {
    event SetAuctionDetails(uint256 indexed projectId, uint256 _auctionTimestampStart, uint256 _auctionTimestampEnd, uint256 _auctionPriceStart);

    using SafeMath for uint256;

    IGenArt721CoreContract public artblocksContract;
    IMinterFilter public minterFilter;
    uint256 constant ONE_MILLION = 1_000_000;

    mapping(address => mapping(uint256 => uint256)) public projectMintCounter;
    mapping(uint256 => uint256) public projectMintLimit;
    mapping(uint256 => bool) public projectMaxHasBeenInvoked;
    mapping(uint256 => uint256) public projectMaxInvocations;
    uint256 public minimumAuctionLengthSeconds = 3600;

    // Auction variables
    mapping(uint256 => AuctionParameters) public projectAuctionParameters;
    struct AuctionParameters {
        uint256 timestampStart;
        uint256 timestampEnd;
        uint256 priceStart;
    }

    constructor(address _genArt721Address, address _minterFilter) public {
        artblocksContract = IGenArt721CoreContract(_genArt721Address);
        minterFilter = IMinterFilter(_minterFilter);
    }

    function setProjectMintLimit(uint256 _projectId, uint8 _limit) public {
        require(
            artblocksContract.isWhitelisted(msg.sender),
            "can only be set by admin"
        );
        projectMintLimit[_projectId] = _limit;
    }

    function setProjectMaxInvocations(uint256 _projectId) public {
        require(
            artblocksContract.isWhitelisted(msg.sender),
            "can only be set by admin"
        );
        uint256 maxInvocations;
        uint256 invocations;
        ( , , invocations, maxInvocations, , , , , ) = artblocksContract.projectTokenInfo(_projectId);
        projectMaxInvocations[_projectId] = maxInvocations;
        if (invocations < maxInvocations) {
            projectMaxHasBeenInvoked[_projectId] = false;
        }
    }

    function setMinimumAuctionLengthSeconds(uint256 _minimumAuctionLengthSeconds) public {
        require(
            artblocksContract.isWhitelisted(msg.sender),
            "can only be set by admin"
        );
        minimumAuctionLengthSeconds = _minimumAuctionLengthSeconds;
    }

    ////// Auction Functions
    function setAuctionDetails(
        uint256 _projectId,
        uint256 _auctionTimestampStart,
        uint256 _auctionTimestampEnd,
        uint256 _auctionPriceStart
    ) public {
        require(
            artblocksContract.isWhitelisted(msg.sender),
            "can only be set by admin"
        );
        require(_auctionTimestampEnd > _auctionTimestampStart, "Auction end must be greater than auction start");
        require(_auctionTimestampEnd > _auctionTimestampStart + minimumAuctionLengthSeconds, "Auction length must be at least minimumAuctionLengthSeconds");
        require(_auctionPriceStart > artblocksContract.projectIdToPricePerTokenInWei(_projectId), "Auction start price must be greater than auction end price");
        projectAuctionParameters[_projectId] = AuctionParameters(
            _auctionTimestampStart,
            _auctionTimestampEnd,
            _auctionPriceStart
        );
        emit SetAuctionDetails(_projectId, _auctionTimestampStart, _auctionTimestampEnd, _auctionPriceStart);
    }

    function purchase(uint256 _projectId)
        public
        payable
        returns (uint256 _tokenId)
    {
        return purchaseTo(msg.sender, _projectId);
    }

    //remove public and payable to prevent public use of purchaseTo function
    function purchaseTo(address _to, uint256 _projectId)
        private
        returns (uint256 _tokenId)
    {
        require(
            !projectMaxHasBeenInvoked[_projectId],
            "Maximum number of invocations reached"
        );
        require(
            msg.value >= getPrice(_projectId),
            "Must send minimum value to mint!"
        );

        //By default, no contract buys
        require(msg.sender == tx.origin, "No Contract Buys");

        // limit mints per address by project
        if (projectMintLimit[_projectId] > 0) {
            require(projectMintCounter[msg.sender][_projectId] < projectMintLimit[_projectId], "Reached minting limit");
            projectMintCounter[msg.sender][_projectId]++;
        }
        _splitFundsETHAuction(_projectId);


        uint256 tokenId = minterFilter.mint(_to, _projectId, msg.sender);
        // What if this overflows, since default value of uint256 is 0?
        // that is intended, so that by default the minter allows infinite transactions,
        // allowing the artblocks contract to stop minting
        // uint256 tokenInvocation = tokenId % ONE_MILLION;
        if (tokenId % ONE_MILLION == projectMaxInvocations[_projectId] - 1) {
            projectMaxHasBeenInvoked[_projectId] = true;
        }
        return tokenId;
    }

    function _splitFundsETHAuction(uint256 _projectId) internal {
        if (msg.value > 0) {
            uint256 pricePerTokenInWei = getPrice(_projectId);
            uint256 refund = msg.value.sub(pricePerTokenInWei);
            if (refund > 0) {
                msg.sender.transfer(refund);
            }
            uint256 foundationAmount = pricePerTokenInWei.div(100).mul(
                artblocksContract.artblocksPercentage()
            );
            if (foundationAmount > 0) {
                artblocksContract.artblocksAddress().transfer(foundationAmount);
            }
            uint256 projectFunds = pricePerTokenInWei.sub(foundationAmount);
            uint256 additionalPayeeAmount;
            if (
                artblocksContract.projectIdToAdditionalPayeePercentage(
                    _projectId
                ) > 0
            ) {
                additionalPayeeAmount = projectFunds.div(100).mul(
                    artblocksContract.projectIdToAdditionalPayeePercentage(
                        _projectId
                    )
                );
                if (additionalPayeeAmount > 0) {
                    artblocksContract
                        .projectIdToAdditionalPayee(_projectId)
                        .transfer(additionalPayeeAmount);
                }
            }
            uint256 creatorFunds = projectFunds.sub(additionalPayeeAmount);
            if (creatorFunds > 0) {
                artblocksContract.projectIdToArtistAddress(_projectId).transfer(
                        creatorFunds
                    );
            }
        }
    }

    function getPrice(uint256 _projectId) public view returns (uint256) {
        AuctionParameters memory auctionParams = projectAuctionParameters[
            _projectId
        ];
        if (getCurrentTime() < auctionParams.timestampStart) {
            return auctionParams.priceStart;
        } else if (getCurrentTime() > auctionParams.timestampEnd) {
            return artblocksContract.projectIdToPricePerTokenInWei(_projectId);
        }
        uint256 elapsedTime = getCurrentTime().sub(
            auctionParams.timestampStart
        );
        uint256 duration = auctionParams.timestampEnd.sub(
            auctionParams.timestampStart
        );
        uint256 startToEndDiff = auctionParams.priceStart.sub(
            artblocksContract.projectIdToPricePerTokenInWei(_projectId)
        );
        return
            auctionParams.priceStart.sub(
                elapsedTime.mul(startToEndDiff).div(duration)
            );
    }

    function isAuctionLive(uint256 _projectId) public view returns (bool) {
        AuctionParameters memory auctionParams = projectAuctionParameters[
            _projectId
        ];
        return (getCurrentTime() < auctionParams.timestampEnd &&
            getCurrentTime() > auctionParams.timestampStart);
    }

    function auctionTimeRemaining(uint256 _projectId)
        public
        view
        returns (uint256)
    {
        AuctionParameters memory auctionParams = projectAuctionParameters[
            _projectId
        ];
        require(isAuctionLive(_projectId), "auction is not currently live");
        return auctionParams.timestampEnd.sub(getCurrentTime());
    }

    function getCurrentTime() internal view returns (uint256) {
        return block.timestamp;
    }
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

// File: contracts/Strings.sol

pragma solidity ^0.5.0;

//https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
library Strings {

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, "", "", "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d) internal pure returns (string memory _concatenatedString) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory _concatenatedString) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        uint i = 0;
        for (i = 0; i < _ba.length; i++) {
            babcde[k++] = _ba[i];
        }
        for (i = 0; i < _bb.length; i++) {
            babcde[k++] = _bb[i];
        }
        for (i = 0; i < _bc.length; i++) {
            babcde[k++] = _bc[i];
        }
        for (i = 0; i < _bd.length; i++) {
            babcde[k++] = _bd[i];
        }
        for (i = 0; i < _be.length; i++) {
            babcde[k++] = _be[i];
        }
        return string(babcde);
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
}

pragma solidity ^0.5.0;

interface IGenArt721CoreContract {
    function isWhitelisted(address sender) external view returns (bool);

    function projectIdToCurrencySymbol(uint256 _projectId)
        external
        view
        returns (string memory);

    function projectIdToCurrencyAddress(uint256 _projectId)
        external
        view
        returns (address);

    function projectIdToArtistAddress(uint256 _projectId)
        external
        view
        returns (address payable);

    function projectIdToPricePerTokenInWei(uint256 _projectId)
        external
        view
        returns (uint256);

    function projectIdToAdditionalPayee(uint256 _projectId)
        external
        view
        returns (address payable);

    function projectIdToAdditionalPayeePercentage(uint256 _projectId)
        external
        view
        returns (uint256);

    function projectTokenInfo(uint256 _projectId)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            bool,
            address,
            uint256,
            string memory,
            address
        );

    function artblocksAddress() external view returns (address payable);

    function artblocksPercentage() external view returns (uint256);

    function mint(
        address _to,
        uint256 _projectId,
        address _by
    ) external returns (uint256 tokenId);
}

pragma solidity ^0.5.0;

interface IMinterFilter {
    function setOwnerAddress(address payable _ownerAddress) external;

    function setMinterForProject(uint256 _projectId, address _minterAddress)
        external;

    function disableMinterForProject(uint256 _projectId) external;

    function mint(
        address _to,
        uint256 _projectId,
        address sender
    ) external returns (uint256);
}