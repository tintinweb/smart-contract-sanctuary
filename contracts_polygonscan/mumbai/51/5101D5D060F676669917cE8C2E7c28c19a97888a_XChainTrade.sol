/**
 *Submitted for verification at polygonscan.com on 2022-01-08
*/

// contracts/XChainTrade.sol
// SPDX-License-Identifier: GPL-3.0

// This is the  NFT sale contract for XChain Tech NFTs (ID 0)
// More info at https://xchain.tech and via email at [email protected]
// To contact the XChain Tech Foundation: [email protected]

pragma solidity ^0.8.7;

// File: IXChainTrade.sol
// XChain Tech Trade Contract

interface IXChainTrade {
    function currentPrice() external view returns(uint256);
    function purchase() external payable;
    function withdraw(uint256 amount, address payable destAddr) external;
    function mint(address to, uint256 id, uint256 amount, uint lockedUntilTimestamp) external;
    function totalSupply(uint256 id) external view returns (uint256);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {return msg.sender;}
    function _msgData() internal view virtual returns (bytes calldata) {return msg.data;}
}

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 */
abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC1155Receiver is IERC165 {
    /**
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external returns (bytes4);

    /**
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(address operator, address from, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external returns (bytes4);
}

interface IERC1155 is IERC165 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

interface IERC1155MetadataURI is IERC1155 {
    function uri(uint256 id) external view returns (string memory);
}

contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;
    mapping(uint256 => mapping(address => uint256)) private _balances;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    string private _uri;
    constructor(string memory uri_) {_setURI(uri_);}
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    function balanceOfBatch(address[] memory accounts, uint256[] memory ids) public view virtual override returns (uint256[] memory) {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");
        uint256[] memory batchBalances = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; ++i) {batchBalances[i] = balanceOf(accounts[i], ids[i]);}
        return batchBalances;
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) public virtual override {
        require(from == _msgSender() || isApprovedForAll(from, _msgSender()), "ERC1155: caller is not owner nor approved");
        _safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public virtual override {
        require(from == _msgSender() || isApprovedForAll(from, _msgSender()), "ERC1155: transfer caller is not owner nor approved");
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function _safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");
        address operator = _msgSender();
        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);
        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {_balances[id][from] = fromBalance - amount;}
        _balances[id][to] += amount;
        emit TransferSingle(operator, from, to, id, amount);
        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    function _safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");
        address operator = _msgSender();
        _beforeTokenTransfer(operator, from, to, ids, amounts, data);
        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }
        emit TransferBatch(operator, from, to, ids, amounts);
        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        address operator = _msgSender();
        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);
        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);
        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        address operator = _msgSender();
        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);
        for (uint256 i = 0; i < ids.length; i++) {_balances[ids[i]][to] += amounts[i];}
        emit TransferBatch(operator, address(0), to, ids, amounts);
        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {}

    function _doSafeTransferAcceptanceCheck(address operator, address from, address to, uint256 id, uint256 amount, bytes memory data) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;
        return array;
    }
}

// File: XChainTrade.sol
// contracts/XChainTrade.sol

contract XChainTrade { 
    mapping(address => uint256) public balance;
    uint256 public currentPrice;

    receive() external payable {
        XChain c = XChain(0x04a3b5C3539F4a3B5265eA3Be40d412C6DA53f6A);
        uint256 incwei = msg.value;
        uint256 price = currentPrice;
        uint256 spent;
        uint minted = c.totalSupply(0);
        uint thedate = block.timestamp;
        uint toBeMinted;
        uint lockUntil = c.addressLockedUntilTimestamp(msg.sender);

        // require(thedate >= 1642204800, "XChain: NFT presale not started yet!"); // If someone try to purchase a package before 15 January 2022
        require(thedate >= 1641684196, "XChain: NFT presale not started yet!"); // Enabled for test at current time

        require(minted < 50000, "Sold Out: Sorry all the XChain NFTs have been sold!"); // Maximum 5000 ID 0 NFTs will be minted
        require(incwei >= price, "XChain: Not enough funds to perform a purchase!"); // if somoone sends less ETH than the price of a single NFT

        if (incwei >= 10 ether && thedate < 1656547200) {
            if (incwei >= 200 ether && minted + 400 <= 5000) {
                uint packages = incwei / 200 ether; // checks how many packages of 200 can be purchased
                uint maxPackages = (5000 - minted) / uint(400); // checks how many packages of 200 are available
                if (maxPackages < packages) {packages = maxPackages;}
                toBeMinted = packages * 400; // how many NFTs will be minted
                spent = packages * 200 ether; // adds the right amount of ETH to the total spent
                incwei -= spent; // removes the amount spent from the budget
                lockUntil = thedate + 3888000; // Locks the account for 45 days since the current time
            }
            
            if (incwei >= 100 ether && minted + toBeMinted + 150 <= 5000) { // else if >= than 100 ETH before 2 hours and 15 minutes from initial time
                spent = spent + 100 ether; // adds 100 ETH to the total spent
                incwei = incwei - 100 ether; // removes 100 ETH from the budget
                toBeMinted = toBeMinted + 150; // adds 150 NFTs to the amount of NFTs to be minted
                if (lockUntil < thedate + 2592000) {lockUntil = thedate + 2592000;} // Locks the account for 30 days since the current time
            }
            
            if (incwei >= 50 ether && minted + toBeMinted + 65 <= 5000) { // else if >= than 50 ETH before 2 hours and 15 minutes from initial time
                spent = spent + 50 ether; // adds 50 ETH to the total spent
                incwei = incwei - 50 ether; // removes 50 ETH from the budget
                toBeMinted = toBeMinted + 65; // adds 65 NFTs to the amount of NFTs to be minted
                if (lockUntil < thedate + 1728000) {lockUntil = thedate + 1728000;} // Locks the account for 20 days since the current time
            }
            
            if (minted + toBeMinted + 11 <= 5000) { // else if >= than 10 ETH before 2 hours and 15 minutes from initial time
                spent = spent + 10 ether; // adds 10 ETH to the total spent
                incwei = incwei - 10 ether; // removes 10 ETH from the budget
                toBeMinted = toBeMinted + 11; // adds 11 NFTs to the amount of NFTs to be minted
                if (lockUntil < thedate + 864000) {lockUntil = thedate + 864000;} // Locks the account for 10 days since the current time
            }
        }
        
        // if (thedate >= 1647302400 && minted + toBeMinted + 1 <= 5000 && incwei >= price) { // the date is after March 15, 2022 
        if (thedate >= 1641684196 && minted + toBeMinted + 1 <= 5000 && incwei >= price) { // enabled for test at current time 

            toBeMinted = incwei / price; // how many NFTs will be minted based on budget
            if (toBeMinted + minted > 5000) {toBeMinted = 5000 - minted;} // removes NFT if total is over 5000
            spent = price * toBeMinted; // adds the right amount of ETH to the total spent
            incwei = incwei - spent; // removes the amount spent from the budget
        }

        require(toBeMinted > 0, "XChain: Sorry you didn't manage to purchase any NFT!"); // if somehow someone has managed to go through the loop and come out with 0 NFTs to be minted

        balance[0x8b8E1624814975aD4D52BFFA7c38C05101675bB7] += spent; // XChainTech.eth gets the amount spent in its balance
        balance[msg.sender] += incwei; // the account that made the purchase gets the change in its balance
        c.mint(msg.sender, 0, toBeMinted, lockUntil); // the NFTs are minted and the account locked until the longest date.
    }

    function setCurrentPrice() public returns(uint256) {
        require(currentPrice != 49.56144107 ether, "XChain: no need to set the price, it has already reached the maximum value.");
        uint thedate = block.timestamp;
        uint256 price = 1 ether;
        if (thedate < 1647302400) {price = 1 ether;} // if before start of sale period 15/03/2022
        else if (thedate > 1695686400) {price = 49.56144107 ether;} // if after NFT price increasing period 26/09/2023
        else { 
           for (uint i=0; i < ((thedate - 1647302400) / uint256(604800)); i++) { // given 48384000 epoch difference from start to end, and / by 80 weeks = 604800
                price = price + ((price * 5) / 100); // price increase by 5 percent per week
            } 
        }
        currentPrice = price;
        return price;
    }

    function withdrawChange() public { 
        require(balance[msg.sender] > 0, "XChain: Not enough balance. Withdraw a lower amount.");
        uint256 amount = balance[msg.sender]; balance[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function recoverLostFunds(address lostAddr) public {
        require(msg.sender == 0x8b8E1624814975aD4D52BFFA7c38C05101675bB7, "XChain: funds recovery can only be done by the foundation");
        if (lostAddr == 0x0000000000000000000000000000000000000000) {
            payable(0x8b8E1624814975aD4D52BFFA7c38C05101675bB7).transfer(address(this).balance);
        } else {
            require(balance[lostAddr] > 0, "XChain: Account has no balance.");
            uint256 amount = balance[lostAddr]; balance[lostAddr] = 0;
            payable(0x8b8E1624814975aD4D52BFFA7c38C05101675bB7).transfer(amount);
        }
    }
}    

contract XChain {
    mapping (address => uint) public addressLockedUntilTimestamp;
    function mint(address to, uint256 id, uint256 amount, uint lockedUntilTimestamp) public virtual {}
    function totalSupply(uint256 id) public view virtual returns (uint256) {}
}