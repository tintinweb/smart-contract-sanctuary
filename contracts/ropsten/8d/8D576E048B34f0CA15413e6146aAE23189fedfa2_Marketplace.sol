/**
 *Submitted for verification at Etherscan.io on 2022-01-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity ^0.8.0;

interface IERC1155 is IERC165 {
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    function ownerOfToken(uint256 _tokenId)
        external
        view
        returns (
            address,
            uint256,
            address,
            uint256
        );

    function burn(
        address from,
        uint256 _tokenId,
        uint256 amount
    ) external returns (bool);
}

pragma solidity ^0.8.0;

interface IERC1155Receiver is IERC165 {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

pragma solidity ^0.8.0;

abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC20 {
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

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeERC20 {
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        require(token.approve(spender, value));
    }
}

contract Marketplace is ERC165 {
    using SafeERC20 for IERC20;

    address payable public admin;
    uint256 public orderNonce;
    address public tokenAddress;
    IERC1155 public ERC1155Interface;
    uint256 public platFee;
    IERC20 public ERC20Interface;

    // bool locked;

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC1155Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    struct Order {
        address seller;
        uint256 tokenId;
        uint256 amount;
        uint256 pricePerNFT;
        uint256 saleType;
        uint256 startTime;
        address paymentToken;
    }

    mapping(uint256 => Order) public order;

    constructor(address _admin) {
        require(_admin != address(0), "Zero address");
        admin = payable(_admin);
        platFee = 10;
    }

    event OrderPlaced(
        Order order,
        uint256 timestamp,
        uint256 nonce,
        uint256 editionNumber
    );

    event OrderBought(
        Order order,
        uint256 timestamp,
        address buyer,
        uint256 nonce,
        uint256 editionNumber
    );

    function setTokenAddress(address _tokenAddress) external returns (bool) {
        require(msg.sender == admin, "Not admin");
        require(_tokenAddress != address(0), "Zero address");
        tokenAddress = _tokenAddress;
        ERC1155Interface = IERC1155(_tokenAddress);
        return true;
    }

    function changeAdmin(address _admin) external returns (bool) {
        require(msg.sender == admin, "Only admin");
        admin = payable(_admin);
        return true;
    }

    function changePlatFee(uint256 _platFee) external returns (bool) {
        require(msg.sender == admin, "Only admin");
        require(_platFee <= 90, "Platform fee too high");
        platFee = _platFee;
        return true;
    }

    function placeOrder(
        address _creator,
        uint256 _tokenId,
        uint256 _editions,
        uint256 _pricePerNFT,
        uint256 _saleType,
        uint256 _startTime,
        address _paymentToken
    ) external returns (bool) {
        require(msg.sender == tokenAddress, "Not token contract");
        require(_creator != address(0), "Zero address for creator");
        //Need to add a check here to test the paymentToken is enabled or not
        if (_startTime < block.timestamp) _startTime = block.timestamp;
        orderNonce = orderNonce + 1;
        order[orderNonce] = Order(
            _creator,
            _tokenId,
            _editions,
            _pricePerNFT,
            _saleType,
            _startTime,
            _paymentToken
        );

        emit OrderPlaced(
            order[orderNonce],
            block.timestamp,
            orderNonce,
            _editions
        );

        return true;
    }

    function importOrder(
        address _creator,
        uint256 _tokenId,
        uint256 _editions,
        uint256 _pricePerNFT,
        uint256 _saleType,
        uint256 _startTime,
        address _paymentToken
    ) external returns (bool) {
        require(_saleType == 0, "Only buy now phase");
        require(_creator != address(0), "Zero address for creator");
        //Need to add a check here to test the paymentToken is enabled or not

        if (_startTime < block.timestamp) _startTime = block.timestamp;

        orderNonce = orderNonce + 1;

        ERC1155Interface.safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId,
            _editions,
            ""
        );
        order[orderNonce] = Order(
            _creator,
            _tokenId,
            _editions,
            _pricePerNFT,
            _saleType,
            _startTime,
            _paymentToken
        );

        emit OrderPlaced(
            order[orderNonce],
            block.timestamp,
            orderNonce,
            _editions
        );

        return true;
    }

    function buyNow(
        uint256 _orderNonce,
        uint256 _copies,
        uint256 tokenAmount
    ) external returns (bool) {
        Order memory _order = order[_orderNonce];
        require(_order.seller != address(0), "Order expired");
        require(_order.saleType == 0, "Wrong saletype");
        require(_order.startTime <= block.timestamp, "Start time not reached");
        require(_order.seller != msg.sender, "Seller can't buy");
        require(_copies > 0 && _copies <= _order.amount, "Incorrect editions");
        require(tokenAmount == (_copies * (_order.pricePerNFT)), "Wrong price");
        require(
            buyNowPayment(_order, msg.sender, tokenAmount),
            "Payment failed"
        );
        ERC1155Interface.safeTransferFrom(
            address(this),
            msg.sender,
            _order.tokenId,
            _copies,
            ""
        );

        emit OrderBought(
            _order,
            block.timestamp,
            msg.sender,
            _orderNonce,
            _copies
        );

        order[_orderNonce].amount = order[_orderNonce].amount - _copies;

        if (order[_orderNonce].amount == 0) delete order[_orderNonce];

        return true;
    }

    function buyNowPayment(
        Order memory _order,
        address user,
        uint256 payAmount
    ) internal returns (bool) {
        uint256 platformCut;
        uint256 creatorsCut;

        platformCut = (payAmount * (platFee)) / (100);
        creatorsCut = payAmount - (platformCut);
        // sendValue(admin, platformCut);
        tokenPay(user, admin, platformCut, _order.paymentToken);
        tokenPay(user, _order.seller, creatorsCut, _order.paymentToken);
        // sendValue(payable(_order.seller), creatorsCut);

        return true;
    }

    function tokenPay(
        address from,
        address to,
        uint256 amount,
        address token
    ) internal _hasAllowance(from, amount, token) returns (bool) {
        ERC20Interface = IERC20(token);
        ERC20Interface.safeTransferFrom(from, to, amount);
        return true;
    }

    modifier _hasAllowance(
        address allower,
        uint256 amount,
        address token
    ) {
        // Make sure the allower has provided the right allowance.
        ERC20Interface = IERC20(token);
        uint256 ourAllowance = ERC20Interface.allowance(allower, address(this));
        require(amount <= ourAllowance, "No allowance");
        _;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Low balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Sending error");
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure returns (bytes4) {
        return (
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            )
        );
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external pure returns (bytes4) {
        return (
            bytes4(
                keccak256(
                    "onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"
                )
            )
        );
    }
}