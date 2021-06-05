/**
 *Submitted for verification at Etherscan.io on 2021-06-05
*/

// File: openzeppelin-solidity\contracts\math\SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: node_modules\openzeppelin-solidity\contracts\GSN\Context.sol

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: openzeppelin-solidity\contracts\ownership\Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts\halalChain.sol

pragma solidity ^0.5.0;

//Modul OpenZeppelin Contract untuk operasi matematika, simple authorization dan mekanisme access control access



contract HalalChain is Ownable {
    using SafeMath for uint;

    address payable contractOwner;
    bool private stopped;

    // Struct livestock 
    struct Livestock {
        string livestockID;
        string supplierID;
        string livestockName;
        string livestockTimeStamp; //logdatetime
        uint256 BlockNumber;
        uint IsSet; 
    }

    //Struct detail livestock
    struct LivestockDetail {
        string livestockID;
        string livestockAnimal;
        string livestockDescription; //geolocation,description, year_established, description_json, halal_status
        string photoHash;
        string livestockQuantity; //quantity dan unitofmeasure
        string livestockUser;   //livestock_user
        uint256 BlockNumber;  
    }

    // Mapping setiap entri livestock
    mapping(string => Livestock) public livestockMap;

    // Mapping setiap entri detail livestock
    mapping(string => LivestockDetail) public livestockDetailMap;

    // Variabel yang menyimpan address ETH wallet untuk setiap entri livestock
    mapping(string => address) public livestockAddressMap;

    /* Array yang menyimpan livestock ID. Digunakan untuk mencari ukuran array
     * Dibuat public untuk mencari length
    */
    string[] public livestockLogIDs;

    /**
     * @dev Event ketika livestock telah dibuat
     */
    event registeredLivestockEvent (
        uint _livestockLogIDIndex,
        string _livestockID,
        uint _livestockBlockNumber
    );

     /**
     * @dev Event ketika livestock detail telah dibuat
     */
    event registeredLivestockDetailEvent (
        string _livestockID,
        uint _livestockBlockNumber
    );

    /** 
    * @dev Struct slaughter
    * operasi perpindahan dari livestock ke slaughter
    * setiap slaughter terhubung dengan livestock sebelumnya
    */
    struct Slaughter{
        string slaughterID;
        string livestockID;
        string slaughterTimeStamp;  // logdatetime
        string slaughterDetail;     // slaughter_housename, slaughter address, slaughter ph, description, geolocation, stunningtype, description_json, halal_status, slaughter user
        uint256 BlockNumber;        // block number dari Livestock submission
        uint IsSet;
    }

    // Variabel menyimpan `Slaughter` struct untuk setiap entri slaughter
    mapping(string => Slaughter) public slaughterMap;

    // Variable address yang menyimpan entri slaughter contoh: untuk Audit. 
    mapping(string => address) public slaughterAddressMap;

    // Array storage Log berisi storage ID
    string[] public slaughterLogIDs;

    /**
     * @dev Event penyimpanan entri slaughter
     */
    event registeredSlaughterEvent (
        uint _slaughterLogIDIndex,
        string _slaughterID,
        uint _slaughterBlockNumber
    );


    /** 
    * @dev Struct storage
    * operasi perpindahan dari slaughter (RPH) ke storage/market
    * Setiap storage terhubung dengan livestock 
    */
    struct Storage {
        string storageID;
        string otherID;      //ID livestock dan slaughter livestock
        string productName; 
        string storageTimeStamp;
        uint256 BlockNumber; 
        uint IsSet;          // indikasi yang menunjukkan bahwa storage submission telah ada
    }

    struct StorageDetail{
        string storageID;
        string marketDetail; //market name, marketaddress
        string storageDetail; // description_json, halal status, packaging date, expiration date, dan storageQuantity 
        string storageUser;
        uint256 BlockNumber; //nomor blok dari storage. hash sebelumnya
    }
    
    // Variabel menyimpan Storage struct untuk setiap entri storage 
    mapping(string => Storage) public storageMap;

    // Variabel menyimpan StorageDetail struct untuk setiap entri storage
    mapping(string => StorageDetail) public storageDetailMap;

    //* Variable address yang menyimpan entri storage contoh: untuk Audit.
    mapping(string => address) public storageAddressMap;

    // Array storage Log berisi storage ID
    string[] public storageLogIDs;

    /**
     * @dev Event penyimpanan entri storage 
     */
    event registeredStorageEvent (
        uint _storageLogIDIndex,
        string _storageID,
        uint _storageBlockNumber
    );

    /**
     * @dev Event penyimpanan entri storage detail
     */
    event registeredStorageDetailEvent (
        string _storageID,
        uint _storageBlockNumber
    );

   /**
     * @dev Constructor
     */
    constructor () public {
        contractOwner = msg.sender;
        stopped = false;
    }

    /**
     * @dev Circuit Breaker
    */
    function toggleContractActive() onlyOwner public returns (bool) {
        stopped = !stopped;
        return stopped;
    }

    /**
     * @dev Throws jika contract berhenti.
    */
    modifier stopInEmergency() {
        require(!stopped, "Halalchain Contract stopped.");
        _;
    }

    /** 
    * @dev Throws jika contract tidak berhenti
    */
    modifier onlyInEmergency() {
        require(stopped, "Halalchain Contract is still running");
        _;
    }

    /**
     * @dev Menambahkan livestock ke dalam blockchain
     * @param _livestockID Unique ID dari livestock e.g. 1b26557b-20f3-4ea2-81d2-e54c5a9a40f7
     * @param _supplierID ID dari supplier
     * @param _livestockName Nama Livestock/poultry
     * @param _livestockTimeStamp Timestamp penambahan livestock e.g. 20210620 16:10:55
     
     */
    function addLivestock( string calldata _livestockID,
                        string calldata _supplierID,
                        string calldata _livestockName,
                        string calldata _livestockTimeStamp
                        )
        stopInEmergency external returns(uint, uint) {

        require(this.checkLivestock(_livestockID) == false, "Error: Failed to add livestock. Livestock ID already registered.");

        uint256 livestockBlockNumber = block.number;
        //test blockhash
        uint256 IsSet = 1;

        livestockMap[_livestockID] = Livestock(_livestockID, _supplierID, _livestockName, _livestockTimeStamp, livestockBlockNumber, IsSet);

        livestockAddressMap[_livestockID] = msg.sender;

        uint livestockLogIDIndex = livestockLogIDs.push(_livestockID);
        livestockLogIDIndex = livestockLogIDIndex.sub(1);
        
        emit registeredLivestockEvent(livestockLogIDIndex, _livestockID, livestockBlockNumber);

        return (livestockLogIDIndex, livestockBlockNumber);
    }

    /**
     * @dev Menambahkan detail livestock
     * @param _livestockID Unique ID untuk livestock
     * @param _livestockAnimal Nama hewan yang diternakan
     * @param _livestockDescription deskripsi tambahan untuk livestock
     * @param _photoHash hasil hash photo
     * @param _livestockQuantity Kuantitas dari livestock dan satuannya
     * @param _livestockUser User yang menyimpan data livestock
     */
    function addLivestockDetails(string calldata _livestockID,
                                string calldata _livestockAnimal,
                                string calldata _livestockDescription,
                                string calldata _photoHash, 
                                string calldata _livestockQuantity, 
                                string calldata _livestockUser)
        stopInEmergency external returns(uint) {

        uint256 livestockBlockNumber = block.number;

        livestockDetailMap[_livestockID] = LivestockDetail(_livestockID, _livestockAnimal, _livestockDescription, _photoHash,
                                        _livestockQuantity, _livestockUser, livestockBlockNumber);

        emit registeredLivestockDetailEvent(_livestockID, livestockBlockNumber);

        return (livestockBlockNumber);
    }

    /**
     * @dev Mengembalikan jumlah livestock yang ada di dalam blockchain
     * Hanya dapat dipanggil oleh owner
     */
    function getLivestockSubmissionsCount() external onlyOwner stopInEmergency view returns(uint) {
        return livestockLogIDs.length;
    }

    /**
     * @dev mengembalikan address yang digunakan ketika mensubmit livestock
     * @param livestock_id Livestock ID yang merupakan primary key dalam livestock map
     * Hanya dapat dipanggil oleh owner
     */
    function getLivestockSubmitterAddress(string calldata livestock_id) external onlyOwner stopInEmergency view returns(address) {
       return livestockAddressMap[livestock_id];
    }

    /**
     * @dev mengembalikan livestock berdasarkan index array
     * @param arrayIndex index array dari livestockLogIDs
     */
    function getLivestockLogIDByIndex(uint256 arrayIndex) external stopInEmergency view returns(string memory) {
       return livestockLogIDs[arrayIndex];
    }

    /**
     * @dev Mengembalikan livestock jika parameter livestock ID ada di dalam database
     * @param livestock_id Livestock ID yang merupakan primary key dalam livestock map 
     * Data location harus mengembalikan tipe memory untuk mengembalikan parameter
     */
    function getLivestockSubmission(string calldata livestock_id) external stopInEmergency view returns (string memory, string memory,string memory,
                                                                                                    string memory, uint, uint) {
        Livestock memory livestockEntry = livestockMap[livestock_id];

        return (livestockEntry.livestockID, livestockEntry.supplierID, livestockEntry.livestockName, 
                livestockEntry.livestockTimeStamp, livestockEntry.BlockNumber, livestockEntry.IsSet);
    }

    /**
     * @dev Mengembalikan detail livestock jika parameter livestockID tersedia dalam database
     * @param livestock_id Livestock ID merupakan primary key dalam livestockMap.
     */
    function getLivestockSubmissionDetail(string calldata livestock_id) external stopInEmergency view returns (
        string memory, string memory, string memory, 
        string memory, string memory, uint
    ){
        LivestockDetail memory livestockEntryDetail = livestockDetailMap[livestock_id];

        return (livestockEntryDetail.livestockID, livestockEntryDetail.livestockAnimal, livestockEntryDetail.livestockDescription,
            livestockEntryDetail.livestockQuantity, livestockEntryDetail.livestockUser, livestockEntryDetail.BlockNumber);
    }

    /**
     * @dev Cek livestock ID sudah terdaftar di database livestock
     * @param livestock_id Livestock ID merupakan primary key dari livestockMap
     */
    function checkLivestock(string memory livestock_id) public stopInEmergency view returns (bool) {
        uint onChainIsSet = livestockMap[livestock_id].IsSet;
        if (onChainIsSet > 0) {
            return true;
          }
        return false;
    }

    /**
     *  @dev Menambahkan data slaughter ke blockchain
     *  @param _slaughterID UUID Slaughter
     *  @param _livestockID UUID Livestock yang digunakan pada slaughter
     *  @param _slaughterTimeStamp Timestamp penambahan slaughter
     *  @param _slaughterDetail Detail slaughter, terdiri dari user, slaughter_housename, slaughter address, slaughter ph, description, geolocation, stunningtype, description_json, halal_status
     */
    function addSlaughter (
        string calldata _slaughterID,
        string calldata _livestockID,
        string calldata _slaughterTimeStamp,  
        string calldata _slaughterDetail
        ) stopInEmergency external returns(uint, uint) {
        require(this.checkSlaughter(_slaughterID) == false, "Error: Failed to add Slaughter to blockchain. Slaughter ID already registered");

        uint256 slaughterBlockNumber = block.number;

        uint256 IsSet = 1;

        slaughterMap[_slaughterID] = Slaughter(_slaughterID, _livestockID, _slaughterTimeStamp, _slaughterDetail, slaughterBlockNumber,  IsSet);

        slaughterAddressMap[_slaughterID] = msg.sender;

        uint slaughterLogIDIndex = slaughterLogIDs.push(_slaughterID);
        slaughterLogIDIndex = slaughterLogIDIndex.sub(1); 

        emit registeredSlaughterEvent(slaughterLogIDIndex, _slaughterID, slaughterBlockNumber);

        return (slaughterLogIDIndex, slaughterBlockNumber);
    }

    /**
     * @dev Mengembalikan jumlah slaughter dalam blockchain
     * Hanya dapat dipanggil oleh owner
     */
    function getSlaughterSubmissionsCount() external onlyOwner stopInEmergency view returns(uint) {
        return slaughterLogIDs.length;
    }

    /**
     * @dev Mengembalikan address dari submitter
     * @param slaughter_id Slaughter ID yang merupakan primary key dalam slaughterMap
     * Fungsi hanya dapat dipanggil oleh owner
     */
    function getSlaughterSubmitterAddress(string calldata slaughter_id) external onlyOwner stopInEmergency view returns(address) {
       return slaughterAddressMap[slaughter_id];
    }

    /**
     * @dev Mengembalikan slaughter ID dari array menggunakan index array
     * @param arrayIndex Indeks array dari slaughterLogID
     */
    function getSlaughterLogIDByIndex(uint256 arrayIndex) external stopInEmergency view returns(string memory) {
       return slaughterLogIDs[arrayIndex];
    }

    /**
     * @dev Fungsi mendapatkan slaughter jika slaughter ID ada di dalam slaughterMap
     * @param slaughter_id slaughter ID merupokan primary key dalam slaughterMap
     */
    function getSlaughterSubmission(string calldata slaughter_id) external stopInEmergency view 
    returns(string memory, string memory, string memory, uint, uint){
        Slaughter memory slaughterEntry = slaughterMap[slaughter_id];
        return (
            slaughterEntry.slaughterID, slaughterEntry.livestockID, slaughterEntry.slaughterDetail,
            slaughterEntry.BlockNumber, slaughterEntry.IsSet
        );
    }

    /**
     * @dev Cek jika slaughter ID sudah ada dalam slaughter
     * @param slaughter_id slaughter ID sebagai primary key dalam slaughterMap
     */
    function checkSlaughter(string memory slaughter_id) public stopInEmergency view returns (bool) {
        uint onChainIsSet = slaughterMap[slaughter_id].IsSet;
        if (onChainIsSet > 0) {
            return true;
          }
        return false;
    }

    /**
     * @dev Untuk menambahkan storage
     * @param _storageID Storage ID
     * @param _otherID Unique ID untuk livestock dan slaughter contoh: 1b26557b-20f3-4ea2-81d2-e54c5a9a40f7
     * @param _productName Nama product
     * @param _storageTimeStamp Timestamp ketika dimasukan ke dalam storage
     */
    function addStorage(
        string calldata _storageID, 
        string calldata _otherID,
        string calldata _productName,
        string calldata _storageTimeStamp
        ) stopInEmergency external returns(uint, uint) {
        require(this.checkStorage(_storageID) == false, "Error: Failed to add storage data to blockchain. Storage ID already registered");

        uint256 storageBlockNumber = block.number;

        uint256 IsSet = 1;

        storageMap[_storageID] = Storage(_storageID, _otherID, _productName, _storageTimeStamp, storageBlockNumber, IsSet);

        storageAddressMap[_storageID] = msg.sender;

        uint storageLogIDIndex = storageLogIDs.push(_storageID);
        storageLogIDIndex = storageLogIDIndex.sub(1);

        emit registeredStorageEvent(storageLogIDIndex, _storageID, storageBlockNumber);

        return (storageLogIDIndex, storageBlockNumber);
    }

   /**
     * @dev Untuk menambahkan storage
     * @param _storageID Storage ID
     * @param _marketDetail Informasi market yang menyimpan hasil slaughtering
     * @param _storageDetail Informasi detatil storage, seperti packaging date, expiration date, dan deskripsi halal critical point
     * @param _storageUser Pengguna yang menambahkan data storage
     */
    function addStorageDetail(
        string calldata _storageID, 
        string calldata _marketDetail,  
        string calldata _storageDetail, 
        string calldata _storageUser
        ) stopInEmergency external returns(uint) {

        uint256 storageBlockNumber = block.number;

        storageDetailMap[_storageID] = StorageDetail(_storageID, _marketDetail, _storageDetail, _storageUser, storageBlockNumber);

        emit registeredStorageDetailEvent(_storageID, storageBlockNumber);

        return (storageBlockNumber);
    }

    /**
     * @dev Mengembalikan jumlah storage dalam blockchain
     * Hanya dapat dipanggil oleh owner
     */
    function getStorageSubmissionsCount() external onlyOwner stopInEmergency view returns(uint) {
        return storageLogIDs.length;
    }

    /**
     * @dev Mengembalikan address dari submitter
     * @param storage_id Storage ID yang merupakan primary key dalam storageMap
     * Fungsi hanya dapat dipanggil oleh owner
     */
    function getStorageSubmitterAddress(string calldata storage_id) external onlyOwner stopInEmergency view returns(address) {
       return storageAddressMap[storage_id];
    }

    /**
     * @dev Mengembalikan storage ID dari array menggunakan index array
     * @param arrayIndex Indeks array dari storageLogID
     */
    function getStorageLogIDByIndex(uint256 arrayIndex) external stopInEmergency view returns(string memory) {
       return storageLogIDs[arrayIndex];
    }

    /**
     * @dev Fungsi mendapatkan storage jika storage ID ada di dalam storageMap
     * @param storage_id Storage ID merupokan primary key dalam storageMap
     */
    function getStorageSubmission(string calldata storage_id) external stopInEmergency view returns 
        (string memory, string memory, string memory, uint, uint) {
        Storage memory storageEntry = storageMap[storage_id];
        return (
            storageEntry.storageID, storageEntry.otherID, storageEntry.productName, 
            storageEntry.BlockNumber, storageEntry.IsSet
        );
    }

    /**
     * @dev Fungsi mendapatkan storage jika storage ID ada di dalam storageMap
     * @param storage_id Storage ID merupokan primary key dalam storageMap
     */
    function getStorageSubmissionDetail(string calldata storage_id) external stopInEmergency view returns 
        (string memory, string memory, string memory, string memory, uint) {
        StorageDetail memory storageEntry = storageDetailMap[storage_id];
        return (
            storageEntry.storageID, storageEntry.marketDetail, storageEntry.storageDetail, 
            storageEntry.storageUser, storageEntry.BlockNumber
        );
    }

    /**
     * @dev Cek jika storage ID sudah ada dalam storage
     * @param storage_id Storage ID sebagai primary key dalam storageMap
     */
    function checkStorage(string memory storage_id) public stopInEmergency view returns (bool) {
        uint onChainIsSet = storageMap[storage_id].IsSet;
        if (onChainIsSet > 0) {
            return true;
          }
        return false;
    }

    /**
     * @dev Cek contract berhenti atau tidak
     */
    function checkContractIsRunning() public view returns (bool) {
        return stopped;
    }

    /**
     * @dev Fallback function yang dieksekusi jika transaksi dengan data 
     * yang tidak valid atau tidak ada data
     */
    function() external {
        revert();
    }

    /**
     * @dev Hapus storage dan code
     * Hanya dapat dipanggil oleh owner contract
     */
    function destroy() public onlyOwner onlyInEmergency {
        selfdestruct(contractOwner);
    }
}