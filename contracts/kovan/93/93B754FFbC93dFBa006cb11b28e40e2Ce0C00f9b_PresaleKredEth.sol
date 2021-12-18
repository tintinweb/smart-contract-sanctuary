/**
 *Submitted for verification at Etherscan.io on 2021-12-17
*/

pragma solidity ^0.8.9;

//SPDX-License-Identifier: MIT Licensed

interface IBEP20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

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

contract VerifySignature {
    address internal signer;

    function verify(
        address _user,
        uint256[3] memory _slotsQty,
        uint256 _nonce,
        bytes memory _sign
    ) public view returns (bool) {
        bytes32 messageHash = getMessageHash(
            _user,
            uint2str(_slotsQty[0]),
            uint2str(_slotsQty[1]),
            uint2str(_slotsQty[2]),
            uint2str(_nonce)
        );
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, _sign) == signer;
    }

    function getMessageHash(
        address _user,
        string memory _slotsQty1,
        string memory _slotsQty2,
        string memory _slotsQty3,
        string memory _nonce
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    _user,
                    _slotsQty1,
                    _slotsQty2,
                    _slotsQty3,
                    _nonce
                )
            );
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        private
        pure
        returns (bytes32)
    {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) private pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        private
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function uint2str(uint256 _i)
        private
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
}

contract PresaleKredEth is VerifySignature {

    // mainnet
    address[2] public coins = [
        0x05A2e4836B906D1E60c8507e6cE21428c1dE1995, // USDT
        0xDB6bbEBdF9515f308e9d9690aeF0796d4fF7F999 // DAI
    ];
    AggregatorV3Interface internal priceFeed =
        AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);

    address payable public owner;
    uint256 public preSaleStartTime;
    uint256 public preSaleEndTime;
    uint256 public soldToken;
    uint256 public amountRaised;

    // Public Presale
    uint256[5] public usdSlots = [4000, 2000, 800];
    uint256[3] public tokensPerSlot = [100000000e18, 33333333e18, 10000000e18];
    address[] public buyers;

    mapping(address => mapping(uint256 => uint256)) public users;
    mapping(address => uint256) public nonce;

    modifier onlyOwner() {
        require(msg.sender == owner, "PreSale: Not an owner");
        _;
    }

    modifier isVerified(
        address _user,
        uint256[3] memory _slotsQty,
        uint256 _nonce,
        bytes memory _sign
    ) {
        require(_nonce > nonce[msg.sender], "Presale: invalid nonce");
        require(
            verify(_user, _slotsQty, _nonce, _sign),
            "Presale: Unverified."
        );
        _;
    }

    event BuyToken(address _user, uint256 _amount);
    event ClaimToken(address _user, uint256 _amount);

    constructor(address _owner,address _signer) {
        owner = payable(_owner);
        signer = _signer;

        // Setting presale time.
        preSaleStartTime = block.timestamp;
        preSaleEndTime = block.timestamp + 10 days;
    }

    receive() external payable {}

    // to buy token during public preSale time => for web3 use
    function buyTokenETH(
        uint256[3] memory _slotsQty,
        uint256 _nonce,
        bytes memory _sign
    ) public payable isVerified(msg.sender, _slotsQty, _nonce, _sign) {
        require(_slotsQty.length == 3, "PreSale: Invalid Slots");
        require(
            block.timestamp >= preSaleStartTime,
            "PreSale: PreSale not started yet"
        );
        require(block.timestamp < preSaleEndTime, "PreSale: PreSale over");
        if (getUserTotalTokens(msg.sender) == 0) {
            buyers.push(msg.sender);
        }
        // Check requried eth for slot.
        uint256 totalUsd = usdSlots[0] * (_slotsQty[0]);
        totalUsd = totalUsd + (usdSlots[1] * (_slotsQty[1]));
        totalUsd = totalUsd + (usdSlots[2] * (_slotsQty[2]));
        require(msg.value >= usdToETH(totalUsd), "PreSale: Invalid Amount");
        amountRaised = amountRaised + (totalUsd);

        uint256 totalTokens;
        for (uint256 i = 0; i < 3; i++) {
            if (_slotsQty[i] > 0) {
                _updateUserData(msg.sender, i, _slotsQty[i]);
                totalTokens = totalTokens + (
                    tokensPerSlot[i] * (_slotsQty[i])
                );
            }
        }

        require(totalTokens > 0, "Presale: not buy any slot.");
        nonce[msg.sender] = _nonce;
        emit BuyToken(msg.sender, totalTokens);
    }

    // to buy token during public preSale time => for web3 use
    function buyToken(
        uint256 choice,
        uint256[3] memory _slotsQty,
        uint256 _nonce,
        bytes memory _sign
    ) public isVerified(msg.sender, _slotsQty, _nonce, _sign) {
        require(_slotsQty.length == 3, "PreSale: Invalid Slots");
        require(choice < coins.length, "PreSale: Invalid token");
        require(
            block.timestamp >= preSaleStartTime,
            "PreSale: PreSale not started yet"
        );
        require(block.timestamp < preSaleEndTime, "PreSale: PreSale over");
        if (getUserTotalTokens(msg.sender) == 0) {
            buyers.push(msg.sender);
        }
        uint256 totalUsd = usdSlots[0] * (_slotsQty[0]);
        totalUsd = totalUsd + (usdSlots[1] * (_slotsQty[1]));
        totalUsd = totalUsd + (usdSlots[2] * (_slotsQty[2]));
        uint256 tokenDecimals = 10**IBEP20(coins[choice]).decimals();
        IBEP20(coins[choice]).transferFrom(
            msg.sender,
            owner,
            totalUsd * (tokenDecimals)
        );
        amountRaised = amountRaised + (totalUsd);

        uint256 totalTokens;
        for (uint256 i = 0; i < 3; i++) {
            if (_slotsQty[i] > 0) {
                _updateUserData(msg.sender, i, _slotsQty[i]);
                totalTokens = totalTokens + (
                    tokensPerSlot[i] * (_slotsQty[i])
                );
            }
        }

        require(totalTokens > 0, "Presale: not buy any slot.");
        nonce[msg.sender] = _nonce;
        emit BuyToken(msg.sender, totalTokens);
    }

    function _updateUserData(
        address _user,
        uint256 slotIndex,
        uint256 _qty
    ) private {
        // Set User data.
        users[_user][slotIndex] = users[_user][slotIndex] + (
            tokensPerSlot[slotIndex] * (_qty)
        );

        // Set total info
        soldToken = soldToken + (tokensPerSlot[slotIndex] * (_qty));
    }

    //this code assumes that 1usd is equal to 1 unit.
    function usdToETH(uint256 value) public view returns (uint256) {
        return value * (1e18) * (10**priceFeed.decimals()) / (getLatestPriceETH());
    }

    function getLatestPriceETH() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    function getUserTotalTokens(address _user)
        public
        view
        returns (uint256 total)
    {
        for (uint256 i = 0; i < usdSlots.length; i++) {
            total = total + (users[_user][i]);
        }
    }

    function updatePriceAggregator(address _feedAddress) public onlyOwner {
        priceFeed = AggregatorV3Interface(_feedAddress);
    }

    function setPublicPreSale(uint256 _startTime, uint256 _endTime)
        external
        onlyOwner
    {
        preSaleStartTime = _startTime;
        preSaleEndTime = _endTime;
    }

    function changeOwner(address payable _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function changeSigner(address _newSigner) external onlyOwner {
        signer = _newSigner;
    }

    function updateCoinAddress(uint256 choice, address _token)
        external
        onlyOwner
    {
        require(choice < coins.length, "Invalid token");
        coins[choice] = _token;
    }

    function withdrawEth(uint256 _amount) external onlyOwner {
        owner.transfer(_amount);
    }

    function withdrawToken(address _token, uint256 _amount) external onlyOwner {
        IBEP20(_token).transfer(owner, _amount);
    }
}