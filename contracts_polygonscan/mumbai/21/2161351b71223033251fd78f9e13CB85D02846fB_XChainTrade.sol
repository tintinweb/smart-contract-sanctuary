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
    ERC1155 token = ERC1155(0x04a3b5C3539F4a3B5265eA3Be40d412C6DA53f6A); // This is the ERC 1155 NFT contract for XChain (on the Mumbai polygon testnet)
    uint256 public currentPrice;

    function setCurrentPrice() public returns(uint256) {

        // for testing we put all the event in a 3h timeframe
        uint timeNow = 1641585600; // in epoch, put the current time (use https://www.epochconverter.com to find the current time)
        uint saleStarts = timeNow + 4500; // 1h after the 15 minutes the normal sales starts (this leave 1h where both presale and sale are running together)
        uint increaseStop = timeNow + 14100; // NFT price increase stop 2h and 40 minutes after start of sale, going through 80 iteration of 5 percent increase

        uint thedate = block.timestamp;
        uint256 price = 1 ether;

        if (thedate < saleStarts) {price = 1 ether;} // if before start of sale period (1h and 15 minute from initial time)
        else if (thedate > increaseStop) {price = 49.56144107 ether;} // if 2h and 40 minutes after start of sale, NFT price stop growing
        else { 
            for (uint i=0; i < ((thedate - saleStarts) / uint256(120)); i++) { // given 9600 epoch difference from start to end, and / by 80 time periods of 2 minutes = 120
                price = price + ((price * 5) / 100); // price increase by 5 percent per week
            } 
        }
        currentPrice = price;
        return price;
    }


    receive() external payable {
        XChain c = XChain(0x04a3b5C3539F4a3B5265eA3Be40d412C6DA53f6A); // This is the ERC 1155 NFT contract for XChain (on the Mumbai polygon testnet)
        uint256 incwei = msg.value;
        uint256 price = currentPrice;
        uint256 spent;
        uint minted = c.totalSupply(0);
        uint thedate = block.timestamp;
        uint toBeMinted;
        uint lockUntil;

        // for testing we put all the event in a 4h timeframe
        uint timeNow = 1641646800 - 2700; // in epoch, put the current time (use https://www.epochconverter.com to find the current time)
        uint presaleStarts = timeNow + 900; // gives 15 minutes from timeNow when there are no sales available
        uint presaleStops = timeNow + 8100; // gives 2 hours, after the fist 15 minutes, for the sales of packages to run
        uint saleStarts = timeNow + 4500; // 1h after the 15 minute the normal sales starts (this leave 1h where both presale and sale are running together)
        uint allSalesStop = timeNow + 10740; // 2h 59m after the initial time, the contract stops working
        bool keepGoing = true;

        // the contract will terminate if one of the following 3 checks fails
        require(thedate < allSalesStop, "XChain: sorry, this contract is no longer in service. Sales are over."); // past a certain date the SC stops working.
        require(minted < 50000, "Sold Out: Sorry all the XChain NFTs have been sold!"); // Maximum 5000 ID 0 NFTs will be minted
        require(thedate >= presaleStarts, "XChain: NFT presale not started yet!"); // If someone try to purchase a package before: Friday, January 7, 2022 12:00:00 PM (GMT)
        require(incwei >= price, "XChain: Not enough funds to perform a purchase!"); // if somoone sends less ETH than the price of a single NFT

        // the purchase of a ETH 200 packet, thus 400 NFTs,
        // the purchase of a ETH 100 packet, thus +150 NFTs,
        // the purchase of a ETH 50 packet, thus +65 NFTs,
        // the purchase of a ETH 10 packet, thus +11 NFTs,
        // the purchase of a single NFT for 1.05 ETH,
        // for a total of 626 NFTs, leaving a balance of 0.95 ETH to the address

        while (incwei >= price && keepGoing == true) { // if there are still funds and something can be bought, stay in the loop
            if (incwei >= 200000000000000000000 && minted + 400 <= 5000 && thedate < presaleStops) { // if >= than 200 ETH before 2 hours and 15 minutes from initial time
                spent = spent + 200000000000000000000; // adds 200 ETH to the bill
                incwei = incwei - 200000000000000000000; // removes 200 ETH from the budget
                toBeMinted = toBeMinted + 400; // adds 400 NFTs to the amount of NFTs to be minted
                lockUntil = thedate + 4200; // lock the account for 70 minutes since the purchase time
            } else if (incwei >= 100000000000000000000 && minted + 150 <= 5000 && thedate < presaleStops) { // else if >= than 100 ETH before 2 hours and 15 minutes from initial time
                spent = spent + 100000000000000000000; // adds 100 ETH to the bill
                incwei = incwei - 100000000000000000000; // removes 100 ETH from the budget
                toBeMinted = toBeMinted + 150; // adds 150 NFTs to the amount of NFTs to be minted
                if (lockUntil < thedate + 3600) {lockUntil = thedate + 3600;} // lock the account for 60 minutes since the purchase time
            } else if (incwei >= 50000000000000000000 && minted + 65 <= 5000 && thedate < presaleStops) { // else if >= than 50 ETH before 2 hours and 15 minutes from initial time
                spent = spent + 50000000000000000000; // adds 50 ETH to the bill
                incwei = incwei - 50000000000000000000; // removes 50 ETH from the budget
                toBeMinted = toBeMinted + 65; // adds 65 NFTs to the amount of NFTs to be minted
                if (lockUntil < thedate + 3000) {lockUntil = thedate + 3000;} // lock the account for 50 minutes since the purchase time
            } else if (incwei >= 10000000000000000000 && minted + 11 <= 5000 && thedate < presaleStops) { // else if >= than 10 ETH before 2 hours and 15 minutes from initial time
                spent = spent + 10000000000000000000; // adds 10 ETH to the bill
                incwei = incwei - 10000000000000000000; // removes 10 ETH from the budget
                toBeMinted = toBeMinted + 11; // adds 11 NFTs to the amount of NFTs to be minted
                if (lockUntil < thedate + 2400) {lockUntil = thedate + 2400;} // lock the account for 40 minutes since the purchase time
            } else if (incwei >= price && minted + 1 <= 5000 && thedate > saleStarts) { // else if more than current NFT price 1h and 15 minute from initial time
                spent = spent + price; // adds the current price of 1 NFT to the bill
                incwei = incwei - price; // removes the current price of 1 NFT from the budget
                toBeMinted = toBeMinted + 1; // adds 1 NFT to the amount of NFTs to be minted
                if (lockUntil < presaleStarts) {lockUntil = presaleStarts;} // if account lock time is before 1h and 15 minute from initial time, set it at 1h and 15 minute from initial time
            } else {
                keepGoing = false; // else stop the loop
            }
        }

        // the contract will terminate if one of the following 4 checks fails
        require(toBeMinted > 0, "XChain: Sorry you didn't manage to purchase any NFT!"); // if somehow someone has managed to go through the loop and come out with 0 NFTs to be minted
        // require(toBeMinted + minted <= 5000, "XChain: Sorry your pourchase went above the total 5000 NFTs limit!"); // if someone managed to go through the loop and purchase more than the available NFTs
        // require(msg.value == spent + incwei, "XChain: PANIC something wrong with money math. Exiting"); // if somehow the amount spent plus the change is different than the amount sent
        // require(lockUntil > 0, "XChain: PANIC something wrong with lock time math. Exiting"); // if the date the account is locked is not being set

        balance[0x8b8E1624814975aD4D52BFFA7c38C05101675bB7] += spent; // XChainTech.eth gets the amount spent in its balance
        balance[msg.sender] += incwei; // the account that made the purchase gets the change in its balance

        c.mint(msg.sender, 0, toBeMinted, lockUntil); // the NFTs are minted and the account locked until the longest date.
    }

    // This is the function to withdraw funds from an account balance
    function withdraw(uint256 amount, address payable destAddr) public { 
        require(amount <= balance[msg.sender], "XChain: Not enough balance. Withdraw a lower amount.");
        balance[msg.sender] -= amount;
        destAddr.transfer(amount);
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
    function mint(address to, uint256 id, uint256 amount, uint lockedUntilTimestamp) public virtual {}
    function totalSupply(uint256 id) public view virtual returns (uint256) {}
}