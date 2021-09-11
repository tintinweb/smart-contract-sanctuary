// هذا العقد خاص للمشاركة في معسكر رواد السياحة
// اسم الفكرة (Your copter)
//  Seham Alosaimi

pragma solidity >=0.7.0 <0.9.0;

import "./Address.sol";

contract Copter {
    using Address for address payable;

    enum STATUS {
        NULL,
        AVIALABLE,
        ACTIVE,
        EXPIRED
    }

    mapping(uint256 => Attraction) public attraction;
    mapping(uint256 => Ticket) public ticket;
    mapping(address => uint256) private _deposits;

    uint256 public nextAttractionId = 1;
    uint256 public nextTicketId = 1;

    struct Attraction {
        uint256 id;
        address owner;
        bytes name;
        bytes32 city;
        bytes description;
        bytes[] pictures;
        bytes location;
        uint256 avilableTickets;
        uint256[] ticketIds;
    }

    struct Ticket {
        uint256 id;
        uint256 attractionId;
        address buyer;
        uint256 price;
        uint256 form;
        uint256 to;
        STATUS status;
    }

    function createAttraction(
        bytes calldata _name,
        bytes32 _city,
        bytes calldata _description,
        bytes[] calldata _pictures,
        bytes calldata _location
    ) public {
        uint256[] memory ticketIds = new uint256[](0);

        attraction[nextAttractionId].id = nextAttractionId;
        attraction[nextAttractionId].owner = msg.sender;
        attraction[nextAttractionId].name = _name;
        attraction[nextAttractionId].city = _city;
        attraction[nextAttractionId].description = _description;

        for (uint256 i = 0; i < _pictures.length; i++) {
            attraction[nextAttractionId].pictures.push(_pictures[i]);
        }

        attraction[nextAttractionId].location = _location;
        attraction[nextAttractionId].ticketIds = ticketIds;

        nextAttractionId++;
    }

    function addTickets(
        uint256 _attractionId,
        uint256 _avilableTickets,
        uint256 _price,
        uint256[] memory _form,
        uint256[] memory _to
    ) public {
        attraction[_attractionId].avilableTickets = _avilableTickets;

        for (uint256 i = 0; i < _avilableTickets; i++) {
            ticket[nextTicketId].attractionId = _attractionId;
            ticket[nextTicketId].price = _price;
            ticket[nextTicketId].form = _form[i];
            ticket[nextTicketId].to = _to[i];
            ticket[nextTicketId].status = STATUS.AVIALABLE;
            attraction[_attractionId].ticketIds.push(nextTicketId);

            nextTicketId++;
        }
    }

    function checkTicket(uint256 _ticketId)
        public
        view
        returns (STATUS status)
    {
        require(
            ticket[_ticketId].status == STATUS.ACTIVE,
            "SHOULD STATUS.ACTIVE"
        );

        if (ticket[_ticketId].to >= block.timestamp) {
            return STATUS.EXPIRED;
        } else {
            return STATUS.ACTIVE;
        }
    }

    function buyTicket(uint256 _ticketId) public payable {
        require(
            ticket[_ticketId].status == STATUS.AVIALABLE,
            "SHOULD STATUS.AVIALABLE"
        );
        require(ticket[_ticketId].price <= msg.value, "msg.value >= price");

        attraction[ticket[_ticketId].attractionId].avilableTickets =
            attraction[ticket[_ticketId].attractionId].avilableTickets -
            1;
        ticket[_ticketId].buyer = msg.sender;
        ticket[nextTicketId].status = STATUS.ACTIVE;

        _deposits[attraction[ticket[_ticketId].attractionId].owner] = msg.value;
    }

    function getAttraction() external view returns (Attraction[] memory) {
        Attraction[] memory _attractions = new Attraction[](
            nextAttractionId - 1
        );
        for (uint256 i = 1; i < nextAttractionId; i++) {
            _attractions[i - 1] = attraction[i];
        }
        return _attractions;
    }

    function geTticket() external view returns (Ticket[] memory) {
        Ticket[] memory _tickets = new Ticket[](nextTicketId - 1);
        for (uint256 i = 1; i < nextTicketId; i++) {
            _tickets[i - 1] = ticket[i];
        }
        return _tickets;
    }

    function withdraw() public {
        require(_deposits[msg.sender] > 0, "Escrow: balance zero");
        uint256 payment = _deposits[msg.sender];
        _deposits[msg.sender] = 0;
        payable(msg.sender).sendValue(payment);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "byzantium",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}