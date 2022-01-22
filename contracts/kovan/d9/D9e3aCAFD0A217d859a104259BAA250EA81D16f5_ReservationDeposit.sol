// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "AggregatorV3Interface.sol";

contract ReservationDeposit {
    uint32 public usdMinReservationDepositEntryFee;

    struct UserWalletProjectAmountFunded {
        string email;
        address walletAddress;
        uint256 amount;
        uint32 developerId;
        uint32 buildingId;
    }

    mapping(string => UserWalletProjectAmountFunded[])
        public addressToUserWalletProjectAmountFunded;
    address public owner;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed, uint32 _minUSDReservationDepositFee)
        public
    {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
        usdMinReservationDepositEntryFee = _minUSDReservationDepositFee;
    }

    function destroySmartContractAndWithdrawAllFunds(address payable _to)
        public
        onlyOwner
    {
        //require(msg.sender == owner, "You are not the owner");
        selfdestruct(_to);
    }

    function withdrawAllFunds(address payable _to) public onlyOwner {
        //require(owner == msg.sender, "You cannot withdraw.");
        //require(paused == false, "Contract Paused");
        _to.transfer(address(this).balance);
    }

    function _toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint256 i = 0; i < bStr.length; i++) {
            // Uppercase character...
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                // So we add 32 to make it lowercase
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    function fund(
        string memory email,
        uint32 developerId,
        uint32 buildingId
    ) public payable {
        uint256 mimimumUSD = usdMinReservationDepositEntryFee * 10**18;
        require(
            getConversionRate(msg.value) >= mimimumUSD,
            "You need to spend more ETH!"
        );
        bool found = false;
        string memory emailLower = _toLower(email);
        for (
            uint32 i = 0;
            i < addressToUserWalletProjectAmountFunded[emailLower].length;
            i++
        ) {
            if (
                // keccak256(
                //     bytes(
                //         _toLower(
                //             addressToUserWalletProjectAmountFunded[emailLower][
                //                 i
                //             ].email
                //         )
                //     )
                // ) ==
                // keccak256(bytes(emailLower)) &&
                addressToUserWalletProjectAmountFunded[emailLower][i]
                    .developerId ==
                developerId &&
                addressToUserWalletProjectAmountFunded[emailLower][i]
                    .buildingId ==
                buildingId &&
                addressToUserWalletProjectAmountFunded[emailLower][i]
                    .walletAddress ==
                msg.sender
            ) {
                addressToUserWalletProjectAmountFunded[emailLower][i]
                    .amount += msg.value;
                found = true;
            }
        }
        if (!found) {
            addressToUserWalletProjectAmountFunded[emailLower].push(
                UserWalletProjectAmountFunded(
                    emailLower,
                    msg.sender,
                    msg.value,
                    developerId,
                    buildingId
                )
            );
        }
    }

    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    // Helper function to check the balance of this contract
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getAddressToUserWalletProjectAmountFunded(
        string memory email,
        uint32 developerId,
        uint32 buildingId
    ) public view returns (uint256, string memory) {
        string memory emailLower = _toLower(email);
        uint256 sumAmount = 0;
        string memory fromWallets;
        for (
            uint32 i = 0;
            i < addressToUserWalletProjectAmountFunded[emailLower].length;
            i++
        ) {
            if (
                // keccak256(
                //     bytes(
                //         _toLower(
                //             addressToUserWalletProjectAmountFunded[emailLower][
                //                 i
                //             ].email
                //         )
                //     )
                // ) ==
                // keccak256(bytes(emailLower)) &&
                addressToUserWalletProjectAmountFunded[emailLower][i]
                    .developerId ==
                developerId &&
                addressToUserWalletProjectAmountFunded[emailLower][i]
                    .buildingId ==
                buildingId
            ) {
                sumAmount += addressToUserWalletProjectAmountFunded[emailLower][
                    i
                ].amount;
                fromWallets = string(
                    abi.encodePacked(
                        fromWallets,
                        "",
                        ";",
                        "",
                        addressToUserWalletProjectAmountFunded[emailLower][i]
                            .walletAddress
                    )
                );
            }
        }
        return (sumAmount, fromWallets);
    }

    // 1000000000
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }

    function getEntranceFee() public view returns (uint256) {
        // mimimumUSD
        uint256 mimimumUSD = usdMinReservationDepositEntryFee * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return (mimimumUSD * precision) / price;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function withdraw(
        string memory email,
        uint32 developerId,
        uint32 buildingId
    ) public payable onlyOwner {
        string memory emailLower = _toLower(email);
        for (
            uint32 i = 0;
            i < addressToUserWalletProjectAmountFunded[emailLower].length;
            i++
        ) {
            if (
                // keccak256(
                //     bytes(
                //         _toLower(
                //             addressToUserWalletProjectAmountFunded[emailLower][
                //                 i
                //             ].email
                //         )
                //     )
                // ) ==
                // keccak256(bytes(emailLower)) &&
                addressToUserWalletProjectAmountFunded[emailLower][i]
                    .developerId ==
                developerId &&
                addressToUserWalletProjectAmountFunded[emailLower][i]
                    .buildingId ==
                buildingId
            ) {
                uint256 value = addressToUserWalletProjectAmountFunded[
                    emailLower
                ][i].amount;
                payable(
                    addressToUserWalletProjectAmountFunded[emailLower][i]
                        .walletAddress
                ).transfer(value);
                addressToUserWalletProjectAmountFunded[emailLower][i]
                    .amount = 0;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}