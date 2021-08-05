/**
 *Submitted for verification at Etherscan.io on 2020-12-15
*/

pragma solidity 0.7.5;

/**
* @dev Worldwide OpenBazaar Resource Finder Naming Service(WorfNS)
* A simple naming service to register handles on FCFS basis
*/
contract WNS {

    event NewHandle(string handle, bytes data, address indexed owner);

    event NewDisplayName(string handle, string displayName);

    event NewImageLocation(string handle, string imageLocation);

    event NewPeerId(string handle, bytes data);

    event OwnershipTransferred(string handle, address indexed newOwner);

    event HandleRemoved(string handle);

    struct Handle{
        address handleOwner;//Owner of the handle
        string handleName;//This should be unqiue in nature
        string displayName;//Need not to be unqiue
        string imageLocation;//Can be an URI or IPNS address
        bytes data;//extra data
    }

    //Unique handle hash versus Handle
    mapping(bytes32=>Handle) handleNameHashVsHandle;

    //addresses who are allowed to handles on other user's behalf
    mapping(address=>bool) public superUsers;

    modifier onlyHandleOwner(string memory handle){
        require(
            handleNameHashVsHandle[keccak256(abi.encodePacked(handle))].handleOwner == msg.sender,
            "Unauthorized access to Handle"
        );
        _;
    }

    modifier handleExists(string memory handle){
        require(
            handleNameHashVsHandle[keccak256(abi.encodePacked(handle))].handleOwner != address(0),
            "Handle does not exists"
        );
        _;
    }

    modifier handleAvailable(string memory handle){
        require(
            handleNameHashVsHandle[keccak256(abi.encodePacked(handle))].handleOwner == address(0),
            "Handle is already taken"
        );
        _;
    }

    modifier nonZeroAddress(address _address){
        require(_address != address(0), "0 address sent");
        _;
    }

    modifier onlySuperUser(){
        require(superUsers[msg.sender], "Not a super user");
        _;
    }

    constructor(address[] memory _superUsers)public {

        for(uint i = 0;i<_superUsers.length;i++){

            superUsers[_superUsers[i]] = true;

        }
    }

    /**
    * @dev Allows super user to add handle on other user's behalf
    * @param owner The address of the owner
    * @param handle Unique Handle
    * @param _displayName Display name of the entity
    * @param _imageLocation URI or IPNS of the image
    * @param _data Extra data
    */
    function addHandle(
        address owner,
        string calldata handle,
        string calldata _displayName,
        string calldata _imageLocation,
        bytes calldata _data
    )
        external
        onlySuperUser
        nonZeroAddress(owner)
    {

        _createHandle(
            owner,
            handle,
            _displayName,
            _imageLocation,
            _data
        );
    }

    /**
    * @dev Method to create new handle
    * @param handle Unique Handle
    * @param _displayName Display name of the entity
    * @param _imageLocation URI or IPNS of the image
    * @param _data Extra data
    */
    function createHandle(
        string calldata handle,
        string calldata _displayName,
        string calldata _imageLocation,
        bytes calldata _data
    )
        external
    {

        _createHandle(
            msg.sender,
            handle,
            _displayName,
            _imageLocation,
            _data
        );
       
    }

    //helper method to add/create new handle in the contract
    function _createHandle(
        address owner,
        string memory handle,
        string memory _displayName,
        string memory _imageLocation,
        bytes memory data
    )
        private
        handleAvailable(handle)
    {

        require(bytes(handle).length>0, "Empty handle name provided");

        bytes32 handleHash = keccak256(abi.encodePacked(handle));

        handleNameHashVsHandle[handleHash] = Handle({
            handleOwner:owner,
            handleName:handle,
            displayName:_displayName,
            imageLocation:_imageLocation,
            data:data
        });

        emit NewHandle(handle, data, owner);
    }

    /**
    * @dev Transfer handle ownership to new address
    * @param handle Handle whose ownership has to be changed
    * @param newOwner Address of the new owner
    */
    function transferOwnership(
        string calldata handle,
        address newOwner
    )
        external
        handleExists(handle)
        onlyHandleOwner(handle)
        nonZeroAddress(newOwner)
    {

        bytes32 handleHash = keccak256(abi.encodePacked(handle));

        require(
            newOwner != handleNameHashVsHandle[handleHash].handleOwner,
            "New owner is same as previous owner"
        );

        handleNameHashVsHandle[handleHash].handleOwner = newOwner;

        emit OwnershipTransferred(handle, newOwner);

    }

    /**
    * @dev Method to change display name of the entity
    * @param handle Handle whose display name has to be changed
    * @param newName New Display Name
    */
    function changeDisplayName(
        string calldata handle,
        string calldata newName
    )
        external
        handleExists(handle)
        onlyHandleOwner(handle)
    {

        require(bytes(newName).length>0, "Empyt names not allowed");

        handleNameHashVsHandle[keccak256(abi.encodePacked(handle))].displayName = newName;

        emit NewDisplayName(handle, newName);
    }

    /**
    * @dev Method to change Location of Image
    * @param handle Handle whose image location has to be changed
    * @param newImageLocation New Image Location
    */
    function changeImageLocation(
        string calldata handle,
        string calldata newImageLocation
    )
        external
        handleExists(handle)
        onlyHandleOwner(handle)
    {

        handleNameHashVsHandle[keccak256(abi.encodePacked(handle))].imageLocation = newImageLocation;

        emit NewImageLocation(handle, newImageLocation);
    }

    /**
    * @dev Method to extra data
    * @param handle Handle whose extra data has to be changed
    * @param data change extra data
    */
    function changePeerId(
        string calldata handle,
        bytes calldata data
    )
        external
        handleExists(handle)
        onlyHandleOwner(handle)
    {

        handleNameHashVsHandle[keccak256(abi.encodePacked(handle))].data = data;

        emit NewPeerId(handle, data);
    }

    /**
    * @dev Method to get handle info about specific handle
    * @param handleName The handle whose info has to be fetched
    */
    function getHandleInfo(
        string calldata handleName
    )
        external
        view
        returns(
            address owner,
            string memory handle,
            string memory displayName,
            string memory imageLocation,
            bytes memory data
        )
    {

        bytes32 handleBytes = keccak256(abi.encodePacked(handleName));

        owner = handleNameHashVsHandle[handleBytes].handleOwner;
        handle = handleNameHashVsHandle[handleBytes].handleName;
        displayName = handleNameHashVsHandle[handleBytes].displayName;
        imageLocation = handleNameHashVsHandle[handleBytes].imageLocation;
        data = handleNameHashVsHandle[handleBytes].data;
    }

    /**
    * @dev Method to check availability of the handle
    * @param handle Handle whose availability has to be checked
    */
    function isHandleAvailable(string calldata handle)external view returns(bool){
        
        return handleNameHashVsHandle[keccak256(abi.encodePacked(handle))].handleOwner == address(0);
    }
    
    /** 
    * @dev Method to remove handleS
    * @param handle Handle to be removed
    */
    function removeHandle(
        string calldata handle
    )
        external
        handleExists(handle)
        onlyHandleOwner(handle)
    {
        
        delete handleNameHashVsHandle[keccak256(abi.encodePacked(handle))];        
        emit HandleRemoved(handle);
    }
}