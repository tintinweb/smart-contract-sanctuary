// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

contract GreenCertificate {

    /** 
    * @dev Event to be emitted when a project is added
    */
    event ProjectAdded(string name);
    /** 
    * @dev Event to be emitted when a project is removed
    */
    event ProjectRemoved(string name);

    // function modifier
    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    // Member variables
    address private _owner;
    address private _company;
    string[] private _projectList;

    // Mapping for certified projects
    mapping(string => bool) _greenProjects;

    constructor(address company) {
        _company = company;
        _owner = msg.sender;
    }

    // Getter functions
    function getOwner() external view returns (address) {
        return _owner;
    }

    function getCompany() external view returns (address) {
        return _company;
    }

    function getProjects() public view returns (string[] memory) {
        return _projectList;
    }

    // Function to check if a project is certified
    function isCertifiedProject(string memory name) external view returns (bool) {
        return (_greenProjects[name]);
    }

    // Functions to add and remove certified projects
    function addProject(string memory name) external onlyOwner {
        _greenProjects[name] = true;
        _projectList.push(name);
        emit ProjectAdded(name);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "./GreenCertificate.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract GreenCertifier {
    using Address for address;

    /**
     * @dev Modifier to allow function to be called only by the contract owner
     */
    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    /**
     * @dev Event to be emmitted when a company certificate is created
     */
    event CompanyCertification(address certificate);

    /**
     * @dev Event to be emmitted when a project is added
     */
    event ProjectCertification(address company, string project);


    // Owner of this contract
    address private _owner;

    // Mapping of company to a green certificate
    mapping(address => GreenCertificate) private _greenCertificates;
    // Mapping of certified companies
    mapping(address => bool) private _certifiedCompanies;


    constructor() {
        _owner = msg.sender;
    }

    // Getter functions
    function getOwner() external view returns (address) {
        return _owner;
    }

    // Function to check if a company is certified
    function isCertifiedCompany(address company) public view returns (bool) {
        return _certifiedCompanies[company];
    }

    // Function to get the address of the company's certificate
    function getCompanyCertificateAddress(address company) public view returns (address) {
        require(isCertifiedCompany(company), "Given company is not certified");
        return address(_greenCertificates[company]);     
    }

    // Function to get a list of certified projects
    function getCertifiedProjects(address company) external view returns (string[] memory) {
        require(isCertifiedCompany(company), "Given company is not certified");
        return _greenCertificates[company].getProjects();
    }

    function isCeritifiedProject(address company, string memory project) external view returns (bool) {
        require(isCertifiedCompany(company), "Given company is not certified");
        GreenCertificate certificate = _greenCertificates[company];
        return certificate.isCertifiedProject(project);
    }


    function createCertificate(address company, string memory project) external onlyOwner {
        // Create certificate for the company if it already does not exist
        if(_certifiedCompanies[company] == false) {
            // Create certificate
            GreenCertificate newCertificate = new GreenCertificate(company);
            _certifiedCompanies[company] = true;
            _greenCertificates[company] = newCertificate;

            // Create an event
            emit CompanyCertification(address(newCertificate));
        } 

        // Add project to the list
        GreenCertificate certificate = _greenCertificates[company];
        certificate.addProject(project);   
        emit ProjectCertification(company, project);      
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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

