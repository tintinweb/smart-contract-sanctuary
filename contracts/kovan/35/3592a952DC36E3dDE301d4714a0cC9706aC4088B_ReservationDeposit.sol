// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "AggregatorV3Interface.sol";

contract ReservationDeposit {
    //TO DO//use CAD instead of USD
    uint32 public usdMinReservationDepositEntryFee;

    struct UserWalletProjectAmountFunded {
        string email;
        address walletAddress;
        uint256 amount;
        uint32 developerId;
        uint32 buildingId;
        uint32 propertyId;
    }

    string[] internal funders;

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

    function setMinUSDReservationDepositFee(uint32 _minUSDReservationDepositFee)
        public
        onlyOwner
    {
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

    function _toString(address account) internal pure returns (string memory) {
        return _toString(abi.encodePacked(account));
    }

    // function _toString(uint256 value) internal pure returns (string memory) {
    //     return _toString(abi.encodePacked(value));
    // }

    function _toString(bytes32 value) internal pure returns (string memory) {
        return _toString(abi.encodePacked(value));
    }

    function _toString(bytes memory data)
        internal
        pure
        returns (string memory)
    {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    function _toString(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function _concatenate(
        string memory a,
        string memory b,
        string memory delimiter
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(a, delimiter, b));
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
        uint32 buildingId,
        uint32 propertyId
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
                    .propertyId ==
                propertyId &&
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
            (bool foundFunder, ) = findFunder(emailLower);
            if (!foundFunder) {
                funders.push(emailLower);
            }
            addressToUserWalletProjectAmountFunded[emailLower].push(
                UserWalletProjectAmountFunded(
                    emailLower,
                    msg.sender,
                    msg.value,
                    developerId,
                    buildingId,
                    propertyId
                )
            );
        }
    }

    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    // Helper function to check the balance of this contract
    function getBalanceETH() public view returns (uint256) {
        return address(this).balance;
    }

    function getAddressToUserWalletProjectAmountFunded(
        string memory email,
        uint32 developerId,
        uint32 buildingId,
        uint32 propertyId
    ) public view returns (uint256, string memory) {
        string memory emailLower = _toLower(email);
        uint256 sumAmount = 0;
        string memory fromWallets = "";
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
                    .propertyId ==
                propertyId
            ) {
                sumAmount += addressToUserWalletProjectAmountFunded[emailLower][
                    i
                ].amount;
                bytes memory fromWalletsBytes = bytes(fromWallets); // Uses memory

                if (fromWalletsBytes.length > 0) {
                    fromWallets = string(
                        _concatenate(
                            fromWallets,
                            _toString(
                                addressToUserWalletProjectAmountFunded[
                                    emailLower
                                ][i].walletAddress
                            ),
                            ","
                        )
                    );
                } else {
                    fromWallets = _toString(
                        addressToUserWalletProjectAmountFunded[emailLower][i]
                            .walletAddress
                    );
                }
            }
        }
        return (sumAmount, fromWallets);
    }

    function getFunders() public view returns (string[] memory) {
        return funders;
    }

    function getFunderByEmail(string memory email)
        public
        view
        returns (string memory)
    {
        string memory emailLower = _toLower(email);
        string memory jsonString;
        for (
            uint32 i = 0;
            i < addressToUserWalletProjectAmountFunded[emailLower].length;
            i++
        ) {
            bytes memory jsonStringBytes = bytes(jsonString); // Uses memory
            if (jsonStringBytes.length > 0) {
                jsonString = string(_concatenate(jsonString, " , ", ""));
            }
            jsonString = string(_concatenate(jsonString, "{", ""));
            jsonString = string(_concatenate(jsonString, ' "amount":', ""));
            jsonString = string(
                _concatenate(
                    jsonString,
                    _toString(
                        addressToUserWalletProjectAmountFunded[emailLower][i]
                            .amount
                    ),
                    ""
                )
            );
            jsonString = string(_concatenate(jsonString, ",", ""));
            jsonString = string(
                _concatenate(jsonString, ' "developerId":', "")
            );
            jsonString = string(
                _concatenate(
                    jsonString,
                    _toString(
                        addressToUserWalletProjectAmountFunded[emailLower][i]
                            .developerId
                    ),
                    ""
                )
            );
            jsonString = string(_concatenate(jsonString, ",", ""));
            jsonString = string(_concatenate(jsonString, ' "buildingId":', ""));
            jsonString = string(
                _concatenate(
                    jsonString,
                    _toString(
                        addressToUserWalletProjectAmountFunded[emailLower][i]
                            .buildingId
                    ),
                    ""
                )
            );
            jsonString = string(_concatenate(jsonString, ",", ""));
            jsonString = string(_concatenate(jsonString, ' "propertyId":', ""));
            jsonString = string(
                _concatenate(
                    jsonString,
                    _toString(
                        addressToUserWalletProjectAmountFunded[emailLower][i]
                            .propertyId
                    ),
                    ""
                )
            );
            jsonString = string(_concatenate(jsonString, ",", ""));
            jsonString = string(
                _concatenate(jsonString, ' "walletAddres":"', "")
            );
            jsonString = string(
                _concatenate(
                    jsonString,
                    _toString(
                        addressToUserWalletProjectAmountFunded[emailLower][i]
                            .walletAddress
                    ),
                    ""
                )
            );
            jsonString = string(_concatenate(jsonString, '" }', ""));
        }
        jsonString = string(_concatenate("[", jsonString, ""));
        jsonString = string(_concatenate(jsonString, "]", ""));
        return jsonString;
    }

    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10**10); // 18 decimals 10000000000
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

    function removeAddressToUserWalletProjectAmountFunded(
        string memory email,
        uint256 index
    ) internal returns (bool) {
        string memory emailLower = _toLower(email);
        if (index >= addressToUserWalletProjectAmountFunded[emailLower].length)
            return false;

        for (
            uint256 i = index;
            i < addressToUserWalletProjectAmountFunded[emailLower].length - 1;
            i++
        ) {
            addressToUserWalletProjectAmountFunded[emailLower][
                i
            ] = addressToUserWalletProjectAmountFunded[emailLower][i + 1];
        }
        //delete addressToUserWalletProjectAmountFunded[emailLower][addressToUserWalletProjectAmountFunded[emailLower].length-1];
        //addressToUserWalletProjectAmountFunded[emailLower].length--;
        addressToUserWalletProjectAmountFunded[emailLower].pop();
        return true;
    }

    function findFunder(string memory email)
        internal
        view
        returns (bool, uint32)
    {
        string memory emailLower = _toLower(email);
        for (uint32 i = 0; i < funders.length; i++) {
            if (
                keccak256(bytes(_toLower(funders[i]))) ==
                keccak256(bytes(emailLower))
            ) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function removeFunder(uint256 index) internal returns (bool) {
        if (index >= funders.length) return false;

        for (uint256 i = index; i < funders.length - 1; i++) {
            funders[i] = funders[i + 1];
        }
        //delete funders[funders.length-1];
        //funders.length--;
        funders.pop();
        return true;
    }

    uint32[] indexesToRemove;

    function refund(
        string memory email,
        uint32 developerId,
        uint32 buildingId,
        uint32 propertyId
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
                buildingId &&
                addressToUserWalletProjectAmountFunded[emailLower][i]
                    .propertyId ==
                propertyId
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
                indexesToRemove.push(i);
            }
        }

        for (uint32 i = 0; i < indexesToRemove.length; i++) {
            removeAddressToUserWalletProjectAmountFunded(
                emailLower,
                indexesToRemove[i]
            );
        }

        delete indexesToRemove;

        if (addressToUserWalletProjectAmountFunded[emailLower].length == 0) {
            delete addressToUserWalletProjectAmountFunded[emailLower];
            (bool foundFunder, uint32 foundFunderIndex) = findFunder(
                emailLower
            );
            if (foundFunder) {
                removeFunder(foundFunderIndex);
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