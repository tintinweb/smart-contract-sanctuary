/**
 *Submitted for verification at Etherscan.io on 2021-02-04
*/

pragma solidity >=0.7.0 <0.8.0;


function onlyBy1(address from, address by1) 
    pure
{
    require(
       from == by1,
        "Sender forbidden"
    );
}

function validIndex(uint index, uint array_size) 
    pure
{
    require(
        index < array_size,
        "Index is not valid"
    );
}

interface Util {
    
    modifier mod_onlyBy2(address by1, address by2) {
        require(
           msg.sender == by1 || msg.sender == by2,
            "Sender not authorized"
        );
        
        _;
    }
    
    modifier mod_refuseTransaction(){
        require(
            false,
            "This contract does not accept incomming transaction"
        );
        
        _;
    }
}

contract License is Util {
    
    event adminChanged(address);
    event ownerChanged(address);
    event expirationTimestampChanged(uint);
    event licenseSetForSale(uint);
    event licenseRemovedFromSale();
    event licenseSold(uint, address, address); // (price, oldOwner, newOwner)
    event deleted();

    address payable public admin; //administrator of the license, basically, who created it
    address payable public owner; //last owner of the license
    Software public softwareLinked;
    uint public expiration_timestamp = 0; // 0 for no expiration date
    bool public license_for_sale = false;
    uint public selling_price = 0;
    
    modifier licenseIsForSale() {
        require(
            license_for_sale,
            "License is not for sale"
        );

        _;
    }
    
    modifier priceOk(uint price) {
        require(
                price >= selling_price,
                "Not enough ether to buy this license"
            );

        _;
    }
    
    constructor (address payable _admin, address payable _owner, uint _expiration_timestamp)
    {
        admin = _admin;
        owner = _owner;
        expiration_timestamp = _expiration_timestamp;
        license_for_sale = false;
        selling_price = 0;
        softwareLinked = Software(msg.sender);
    }
    
    function destroy()
        public
    {
        onlyBy1(msg.sender, address(softwareLinked));

        emit deleted();
        selfdestruct(admin);
    }
    
    // whenever you send a payement to this contract, it automatically goes here
    receive() 
        external
        payable
        licenseIsForSale()
        priceOk(msg.value)
    {
        emit licenseSold(msg.value, owner, msg.sender);
        softwareLinked.licenseHasChangedOwner(owner, msg.sender);
        
        owner.transfer(msg.value);
        owner = msg.sender;
        emit ownerChanged(owner);
        
        remove_for_sale();
    }
    
    function get_informations ()
        public
        view
        returns (address payable, address payable, Software, uint, bool, uint, address)
    {
        return (admin, owner, softwareLinked, expiration_timestamp, license_for_sale, selling_price, address(this));
    }
    
    function set_for_sale(uint _selling_price) 
        public
        //onlyBy(owner)
    {
        onlyBy1(msg.sender, owner);

        license_for_sale = true;
        selling_price = _selling_price;
        emit licenseSetForSale(_selling_price);
    }
    
    function remove_for_sale()
        public
        licenseIsForSale
    {
        onlyBy1(msg.sender, owner);

        license_for_sale = false;
        selling_price = 0;
        emit licenseRemovedFromSale();
    }
    
    function set_owner(address payable new_owner)
        public
        mod_onlyBy2(owner, admin)
    {
        // onlyBy2(msg.sender, owner, admin);

        softwareLinked.licenseHasChangedOwner(owner, new_owner);
        owner = new_owner;
        emit ownerChanged(owner);
    }
    
    function set_admin(address payable new_admin)
        public
    {
        onlyBy1(msg.sender, admin);

        admin = new_admin;
        emit adminChanged(admin);
    }
    
    function set_expiration_timestamp(uint new_timestamp)
        public
    {
        onlyBy1(msg.sender, admin);

        expiration_timestamp = new_timestamp;
        emit expirationTimestampChanged(expiration_timestamp); //expirationTimestampChanged(expiration_timestamp);
    }
    
    function remove_expiration_timestamp()
        public
    {
        onlyBy1(msg.sender, admin);

        set_expiration_timestamp(0);
    }
    
    function check_owner(address _owner)
        public
        view
        returns (bool)
    {
        return _owner == owner && (expiration_timestamp >= block.timestamp || expiration_timestamp == 0);
    }
}

contract Software is Util {
    
    event adminChanged(address);
    event nameChanged(string);
    event versionChanged(string);
    event defaultLicenseTimeChanged(uint);
    event licenseAdded(address);
    event deleted();
    event licenceDeleted(address);
    
    SoftwareHandler public softwareHandler;
    address payable public admin;
    License[] public licenses;
    mapping (address => License) public ownerLicense;
    mapping (License => uint) public licenseIndex;

    string public name;
    string public version;
    uint public license_time_default; // license time-to-live in second. 0 for infinite
    
    modifier ownerLicenseMatch(address owner, License license) {
        require (
            ownerLicense[owner] == license,
            "Invalid License or owner."
        );
        
        _;
    }
    
    modifier licenseExists(License _license) {
        require (
            licenseIndex[_license] != 0 || (licenses.length > 0 && _license == licenses[0]),
            "License does not exist"
        );
        
        _;
    }
    
    constructor (string memory _name, string memory _version, uint _license_time_default, address payable _admin)
    {
        name = _name;
        version = _version;
        license_time_default = _license_time_default;
        admin = _admin;
        softwareHandler = SoftwareHandler(msg.sender);
    }
    
    function destroy()
        public
    {
        onlyBy1(msg.sender, address(softwareHandler));

        remove_all_licenses();
        
        emit deleted();
        selfdestruct(admin);
    }
    
    receive()
        external
        payable
        mod_refuseTransaction
    {}
    
    function licenseHasChangedOwner(address oldOwner, address newOwner) 
        public
        ownerLicenseMatch(oldOwner, License(msg.sender))
    {
        delete ownerLicense[oldOwner];
        ownerLicense[newOwner] = License(msg.sender);
    }
    
    function check_license(address adr)
        public
        view
        returns (bool)
    {
        if (ownerLicense[adr] == License(0)) // user do not have at least one license at his name
            return false; 
            
        if (ownerLicense[adr].check_owner(adr))
            return true;
            
        // the user may have multiple license at his name.
        License[] memory licenseOwner = get_licenses_with_owner(adr);
        
        for (uint i = 0 ; i < licenseOwner.length ; i++) {
            if (licenseOwner[i].check_owner(adr))
                return true;
        }
        
        return false;
    }
    
    function set_admin(address payable _admin)
        public
    {
        onlyBy1(msg.sender, admin);

        admin = _admin;
        emit adminChanged(admin);
    }
    
    function set_name(string calldata _name)
        public
    {
        onlyBy1(msg.sender, admin);

        name = _name;
        emit nameChanged(name);
    }
    
    function set_version(string calldata _version)
        public
    {
        onlyBy1(msg.sender, admin);

        version = _version;
        emit versionChanged(version);
    }
    
    function set_license_time_default(uint _license_time_default)
        public
    {
        onlyBy1(msg.sender, admin);

        license_time_default = _license_time_default;
        emit defaultLicenseTimeChanged(license_time_default);
    }
    
    function get_informations ()
        public
        view
        returns (string memory, string memory, uint, address payable, uint, address)
    {
        return (name, version, license_time_default, admin, licenses.length, address(this));
    }
    
    function get_license_informations (uint license_index)
        public
        view
        returns (address payable, address payable, Software, uint, bool, uint, address)
    {
        validIndex(license_index, licenses.length);

        return licenses[license_index].get_informations();
    }
    
    function get_licenses_for_sale (bool _for_sale)
        public
        view
        returns (License[] memory)
    {
        uint counter = 0;
        for (uint i = 0 ; i < licenses.length ; i++) {
            if (licenses[i].license_for_sale() == _for_sale) {
                counter++;
            }
        }

        License[] memory ret = new License[](counter);
        uint j = 0;
        for (uint i = 0; i < licenses.length ; i++) {
            if (licenses[i].license_for_sale() == _for_sale) {
                ret[j] = licenses[i];
                j++;
            }
        }
        
        return ret;
    }
    
    function add_license() // default value: admin:admin, owner:admin, expiration: 0
        public
        returns (License)
    {
        onlyBy1(msg.sender, admin);

        return add_license(admin, payable(admin));
    }
    
    function add_license(address payable _owner)  // default value: admin:admin, owner:owner, expiration: 0
        public
        returns (License)
    {
        onlyBy1(msg.sender, admin);

        return add_license(admin, _owner);
    }
    
    function add_license(address payable _owner, uint _expiration_timestamp) // default value: admin:admin, owner:owner, expiration: exp
        public
        returns (License)
    {
        onlyBy1(msg.sender, admin);

        return add_license(admin, _owner, _expiration_timestamp);
    }
    
    function add_license(address payable _admin, address payable _owner)  // default value: admin:admin, owner:owner, expiration: 0
        public
        returns (License)
    {
        onlyBy1(msg.sender, admin);

        if (license_time_default == 0)
            return add_license(_admin, _owner, 0);
        else
            return add_license(_admin, _owner, block.timestamp + license_time_default);
    }
    
    function add_license(address payable _admin, address payable _owner, uint _expiration_timestamp)
        public
        returns (License)
    {
        onlyBy1(msg.sender, admin);

        License newLicense = new License(_admin, _owner, _expiration_timestamp);
        licenses.push(newLicense);
        
        ownerLicense[_owner] = newLicense;
        licenseIndex[newLicense] = licenses.length-1;
        emit licenseAdded(address(newLicense));
        
        return newLicense;
    }
    
    function get_nb_license()
        public
        view
        returns (uint) 
    {
        return licenses.length;
    }
    
    function get_licenses_with_admin(address _admin)
        public 
        view
        returns (License[] memory)
    {
        uint counter = 0;
        for (uint i = 0 ; i < licenses.length ; i++) {
            if (licenses[i].admin() == _admin) {
                counter++;
            }
        }
        
        License[] memory ret = new License[](counter);
        uint j = 0;
        for (uint i = 0; i < licenses.length ; i++) {
            if (licenses[i].admin() == _admin) {
                ret[j] = licenses[i];
                j++;
            }
        }
        
        return ret;
    }
    
    function get_licenses_with_owner(address _owner)
        public 
        view
        returns (License[] memory)
    {
        uint counter = 0;
        for (uint i = 0 ; i < licenses.length ; i++) {
            if (licenses[i].owner() == _owner) {
                counter++;
            }
        }
        
        License[] memory ret = new License[](counter);
        uint j = 0;
        for (uint i = 0; i < licenses.length ; i++) {
            if (licenses[i].owner() == _owner) {
                ret[j] = licenses[i];
                j++;
            }
        }
        
        return ret;
    }
    
    function remove_license(License _license) 
        public
        licenseExists(_license)
    {
        onlyBy1(msg.sender, admin);

        remove_license(licenseIndex[_license]);
    }
    
    function remove_license(uint index)
        public
    {
        onlyBy1(msg.sender, admin);
        validIndex(index, licenses.length);

        // cache owner and license adr
        address payable owner = licenses[index].owner();
        address license_adr = address(licenses[index]);
        
        // destroy contract
        licenses[index].destroy();
        
        // emit the change
        emit licenceDeleted(license_adr);
        
        // adjust mapping index
        delete licenseIndex[licenses[index]];
        
        // rearrange array
        for (uint i = index; i < licenses.length-1; i++)
        {
          // shift license in the array
            licenses[i] = licenses[i+1];
            
            // apply the shift to the mapping 
            licenseIndex[licenses[i]] = i;
        }

        // remove last element
        licenses.pop();
        
        if (address(ownerLicense[owner]) == license_adr)  {
        
            // try to find another license for the owner cached
            License[] memory licenses_same_owner = get_licenses_with_owner(owner);
            
            // updating the mapping ownerLicense
            if (licenses_same_owner.length > 0) {
                ownerLicense[owner] = licenses_same_owner[0];
            }
            else {
                delete ownerLicense[owner];
            }
        }
    }
    
    function remove_all_licenses()
        public
        mod_onlyBy2(admin, address(softwareHandler))
    {
        // onlyBy2(msg.sender, admin, address(softwareHandler));

        for (uint i = 0; i < licenses.length; i++) {
            
            // update mapping ownerLicense
            delete ownerLicense[licenses[i].owner()];
            
            // save license contract adr
            address license_adr = address(licenses[i]);
            
            // destroy contract
            licenses[i].destroy();
            
            // emit the change
            emit licenceDeleted(license_adr);
        }

        delete licenses; //remove all elements from array
    }
}

contract SoftwareHandler is Util {
    event softwareAdded(address);
    event softwareDeleted(address);

    Software[] public softwares;
    mapping (Software => uint) public softwareIndex; 
    
    modifier softwareExists(Software _software) {
        require (
            softwareIndex[_software] != 0 || (softwares.length > 0 && _software == softwares[0]),
            "Software does not exist"
        );
        
        _;
    }

    receive() 
        external
        payable
        mod_refuseTransaction
    {}
    
    function addSoftware(string calldata name, string calldata version) 
        public 
        returns (Software) 
    {
        return addSoftware(name, version, 0, msg.sender);
    }
    
    function addSoftware(string calldata name, string calldata version, uint license_time_default) 
        public 
        returns (Software) 
    {
        return addSoftware(name, version, license_time_default, msg.sender);
    }
    
    function addSoftware(string calldata name, string calldata version, uint license_time_default, address payable admin) 
        public
        returns (Software)
    {
        Software newSoftware = new Software(name, version, license_time_default, admin);
        softwares.push(newSoftware);
        
        softwareIndex[newSoftware] = softwares.length-1;

        emit softwareAdded(address(newSoftware));
        
        return newSoftware;
    }
    
    function getNbOfSoftware() 
        public 
        view 
        returns (uint) 
    {
        return softwares.length;
    }
    
    function get_softwares_with_admin(address _admin)
        public 
        view
        returns (Software[] memory)
    {
        uint counter = 0;
        for (uint i = 0 ; i < softwares.length ; i++) {
            if (softwares[i].admin() == _admin) {
                counter++;
            }
        }
        
        Software[] memory ret = new Software[](counter);
        uint j = 0;
        for (uint i = 0; i < softwares.length ; i++) {
            if (softwares[i].admin() == _admin) {
                ret[j] = softwares[i];
                j++;
            }
        }
        
        return ret;
    }
    
    // return licenses filtered by admin, owner and for_sale status
    // for _admin and _owner, if they are = 0x0, not filtered
    // for sale:
    //      - 0: filter by licenses that are not for sale
    //      - 1: filter by licenses that are for sale
    //      - 2 or more: do not filter by for sale.
    function getLicenses(address _admin, address _owner, uint8 _for_sale)
        public
        view
        returns (License[] memory)
    {
        require (
            !(_admin == address(0) && _owner == address(0) && _for_sale >= 2)
            // ,
            // "You need at least one active filter."
        );
        
        
        bool _for_sale_bool = (_for_sale == 1);
        uint counter = 0;
        for (uint i = 0 ; i < softwares.length ; i++) {
            Software current_software = softwares[i];
            for (uint j=0 ; j < current_software.get_nb_license() ; j++) {
                License current_license = current_software.licenses(j);
                if ( (_admin == address(0) || current_license.admin() == _admin) &&
                     (_owner == address(0) || current_license.owner() == _owner) &&
                     (_for_sale >= 2 || current_license.license_for_sale() == _for_sale_bool) )
                {
                    counter++;
                }
            }
        }
        
        License[] memory ret = new License[](counter);
        uint counter2 = 0;
        for (uint i = 0 ; i < softwares.length ; i++) {
            Software current_software = softwares[i];
            for (uint j=0 ; j < current_software.get_nb_license() ; j++) {
                License current_license = current_software.licenses(j);
                if ( (_admin == address(0) || current_license.admin() == _admin) &&
                     (_owner == address(0) || current_license.owner() == _owner) &&
                     (_for_sale >= 2 || current_license.license_for_sale() == _for_sale_bool) )
                {
                    ret[counter2] = current_license;
                    counter2++;
                }
            }
        }
        
        return ret;
    }
    
    function removeSoftware(Software _software) 
        public
        softwareExists(_software)

    {
        onlyBy1(msg.sender, _software.admin());

        removeSoftware(softwareIndex[_software]);
    }
    
    function removeSoftware(uint index)
        public
        // mod_validIndex(index, softwares.length)
    {
        onlyBy1(msg.sender, softwares[index].admin());
        validIndex(index, softwares.length);


        // cache software adr
        address software_adr = address(softwares[index]);
        
        // destroy contract
        softwares[index].destroy();
        
        // emit the deletion
        emit softwareDeleted(software_adr);
        
        // adjust mapping index
        delete softwareIndex[softwares[index]];
        
        // rearrange array
        for (uint i = index; i < softwares.length-1; i++)
        {
            // shift software in the array
            softwares[i] = softwares[i+1];
            
            // apply the shift to the mapping 
            softwareIndex[softwares[i]] = i;
        }

        // remove last element
        softwares.pop();
    }
}