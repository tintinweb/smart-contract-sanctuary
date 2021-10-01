/**
 *Submitted for verification at Etherscan.io on 2021-10-01
*/

pragma solidity ^0.6.11;

// pragma experimental ABIEncoderV2;

interface IERC721 {
    function burn(uint256 tokenId) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function mint(
        address _to,
        uint256 _tokenId,
        string calldata _uri,
        string calldata _payload
    ) external;

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool);

    function ownerOf(uint256 _tokenId) external returns (address _owner);

    function getApproved(uint256 _tokenId) external returns (address);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;
}
interface IERC20 {
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
contract SwapNFT {
    struct Order {
        uint256 tokenId;
        address nftAddress;
        address buyer;
        address payable seller;
        uint256 price;
        uint256 fee; 
        uint256 royalityPercent;
        address payable royalityAddress;
    }
    address public owner;
    uint256 public orderFee;
    address payable benefactor;
    IERC20 public token;

    mapping(uint256 => Order) public pendingOrders;
    mapping(uint256 => Order) public completedOrders;
    mapping(uint256 => Order) public cancelledOrders;

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor(uint256 fee,address _token) public {
        require(fee <= 10000);
        //creating instance of Erc20 token
        token=IERC20(_token);
        orderFee = fee;
        benefactor = msg.sender;
        owner = msg.sender;
    }

    function _computeFee(uint256 _price) public view returns (uint256) {
        return (_price * orderFee) / 10000;
    }

    function computeRoyality(uint256 _price, uint256 _royality)
        public
        pure
        returns (uint256)
    {
        return (_price * _royality) / 10000;
    }

    function changeFee(uint256 fee) public isOwner() {
        require(fee <= 10000);
        orderFee = fee;
    }

    function changeBenefactor(address payable newBenefactor) public isOwner() {
        benefactor = newBenefactor;
    }

    function purchaseOrder(uint256 orderNumber,uint256 _amountOfToken) public payable {
        Order memory order = pendingOrders[orderNumber];
        //Erc20 token balance checker statement
        require(token.balanceOf(msg.sender)>=_amountOfToken,"You don't have enough balance");
        //Erc20 token approve require statement
        require(token.allowance(msg.sender,address(this))>=_amountOfToken,"need to approve token first");
        //statement to check either given amount of token is equal to the price of order
        require(_amountOfToken == order.price, "Not enough payment included");
        //ERC721 approved or not checker statement
        require(
            IERC721(order.nftAddress).getApproved(order.tokenId) ==
                address(this),
            "Needs to be approved"
        );
        require(
            IERC721(order.nftAddress).isApprovedForAll(
                order.seller,
                address(this)
            ) == true,
            "Needs to be approved"
        );
        IERC721(order.nftAddress).safeTransferFrom(
            order.seller,
            msg.sender,
            order.tokenId
        );
        //transfer token from purchaser to contract
        token.transferFrom(msg.sender,address(this),_amountOfToken);
        uint256 _fee = _computeFee(order.price);
        uint256 _royality = computeRoyality(order.price, order.royalityPercent);

        // order.seller.transfer(order.price - (_fee + _royality));
        token.transfer(order.seller,order.price - (_fee + _royality));
        // benefactor.transfer(_fee);
        token.transfer(benefactor,_fee);
        // order.royalityAddress.transfer(_royality);
        token.transfer(order.royalityAddress,_royality);

        order.buyer = msg.sender;
        order.fee = _fee;
        completedOrders[orderNumber] = order;
        delete pendingOrders[orderNumber];
    }

    function cancelOrder(uint256 orderNumber) public {
        Order memory order = pendingOrders[orderNumber];
        require(order.seller == msg.sender, "Only order placer can cancel");
        cancelledOrders[orderNumber] = order;
        delete pendingOrders[orderNumber];
    }

    // Client side, should first call [NFTADDRESS].approve(Swap.sol.address, tokenId)
    // in order to authorize this contract to transfer nft to buyer
    function addOrder(
        address nftAddress,
        uint256 tokenId,
        uint256 price,
        uint256 orderNumber,
        uint256 royalityPercent,
        address payable royalityAddress
    ) public {
        require(
            IERC721(nftAddress).isApprovedForAll(msg.sender, address(this)) ==
                true,
            "Needs to be approved"
        );
        pendingOrders[orderNumber] = Order(
            tokenId,
            nftAddress,
            address(this),
            msg.sender,
            price,
            0,
            royalityPercent,
            royalityAddress
        );
    }

    // Client side, should first call [NFTADDRESS].approve(Swap.sol.address, tokenId)
    // in order to authorize this contract to transfer nft to buyer
    function addMultiOrder(
        address nftAddress,
        uint256[] memory tokenId,
        uint256 price,
        uint256[] memory orderNumber,
        uint256 royalityPercent,
        address payable royalityAddress
    ) public {
        require(
            IERC721(nftAddress).isApprovedForAll(msg.sender, address(this)) ==
                true,
            "Needs to be approved"
        );

        for (uint256 i = 0; i < tokenId.length; i++) {
            pendingOrders[orderNumber[i]].tokenId = tokenId[i];
            pendingOrders[orderNumber[i]].nftAddress = nftAddress;
            pendingOrders[orderNumber[i]].buyer = address(this);
            pendingOrders[orderNumber[i]].seller = msg.sender;
            pendingOrders[orderNumber[i]].price = price;
            pendingOrders[orderNumber[i]].royalityPercent = royalityPercent;
            pendingOrders[orderNumber[i]].royalityAddress = royalityAddress;
        }
    }

    function getAddressFromSignature(
        uint256 _tokenId,
        uint256 _nonce,
        bytes memory signature
    ) public pure returns (address) {
        bytes32 hash = keccak256(
            abi.encodePacked(concat(uintToStr(_tokenId), uintToStr(_nonce)))
        );
        address addressFromSig = recoverSigner(hash, signature);
        return addressFromSig;
    }

    function concat(string memory a, string memory b)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(a, b));
    }

    /**
     * @dev Recover signer address from a message by using their signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param sig bytes signature, the signature is generated using web3.eth.sign(). Inclusive "0x..."
     */
    function recoverSigner(bytes32 hash, bytes memory sig)
        internal
        pure
        returns (address)
    {
        require(sig.length == 65, "Require correct length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        // Divide the signature in r, s and v variables
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28, "Signature version not match");

        return recoverSigner2(hash, v, r, s);
    }

    function recoverSigner2(
        bytes32 h,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, h));
        address addr = ecrecover(prefixedHash, v, r, s);

        return addr;
    }

    /// @notice converts number to string
    /// @dev source: https://github.com/provable-things/ethereum-api/blob/master/oraclizeAPI_0.5.sol#L1045
    /// @param _i integer to convert
    /// @return _uintAsString
    function uintToStr(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        uint256 number = _i;
        if (number == 0) {
            return "0";
        }
        uint256 j = number;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (number != 0) {
            bstr[k--] = bytes1(uint8(48 + (number % 10)));
            number /= 10;
        }
        return string(bstr);
    }   
}