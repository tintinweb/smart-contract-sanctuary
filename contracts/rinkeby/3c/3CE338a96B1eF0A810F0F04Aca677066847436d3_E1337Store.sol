// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./IERC20Token.sol";
import "./IERC721Token.sol";

contract E1337Store is Ownable {
    address erc721owner;
    address erc20TokenAddress;
    address erc721ContractAddress;
    mapping(uint256 => uint256) nextIdForModel;
    mapping(uint256 => uint256) limitIdForModel;
    mapping(uint256 => uint256) priceForModel;

    function purchase(uint256 _modelId) external {
        uint256 nextId = nextIdForModel[_modelId];
        require(
            nextId >= limitIdForModel[_modelId],
            "The collection is sold out"
        );

        /*ERC20Token erc20 = ERC20Token(erc20TokenAddress);
        require(
            erc20.transferFrom(
                msg.sender,
                address(this),
                priceForModel[_modelId]
            ),
            "ERC20 transferFrom failed"
        );*/

        ERC721Token token = ERC721Token(erc721ContractAddress);
        require(
            token.transferFrom(erc721owner, msg.sender, nextId),
            "ERC721 transferFrom failed"
        );

        nextIdForModel[_modelId]--;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawERC20() external onlyOwner {
        ERC20Token token = ERC20Token(erc20TokenAddress);
        uint256 balance = token.balanceOf(address(this));
        if (balance > 0) {
            require(token.transfer(msg.sender, balance), "transfer failed");
        }
    }

    function getERC721Owner() external view returns (address) {
        return erc721owner;
    }

    function setERC721Owner(address _address) external {
        erc721owner = _address;
    }

    function getNextIdForModel(uint256 _model) external view returns (uint256) {
        return nextIdForModel[_model];
    }

    function setNextIdForModel(uint256 _model, uint256 _nextId)
        external
        onlyOwner
    {
        nextIdForModel[_model] = _nextId;
    }

    function getLimitIdForModel(uint256 _model)
        external
        view
        returns (uint256)
    {
        return limitIdForModel[_model];
    }

    function setLimitIdForModel(uint256 _model, uint256 _limitId)
        external
        onlyOwner
    {
        limitIdForModel[_model] = _limitId;
    }

    function getERC721ContractAddress() external view returns (address) {
        return erc721ContractAddress;
    }

    function setERC721ContractAddress(address _address) external onlyOwner {
        erc721ContractAddress = _address;
    }

    function getERC20TokenAddress() external view returns (address) {
        return erc20TokenAddress;
    }

    function setERC20TokenAddress(address _address) external onlyOwner {
        erc20TokenAddress = _address;
    }

    function getPriceForModel(uint256 _model) external view returns (uint256) {
        return priceForModel[_model];
    }

    function setPriceForModel(uint256 _model, uint256 price)
        external
        onlyOwner
    {
        priceForModel[_model] = price;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface ERC20Token {
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function transfer(address _to, uint256 _value)
        external
        returns (bool success);

    function balanceOf(address _owner) external returns (uint256 balance);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface ERC721Token {
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

