contract Colleague {
    address owner;
    struct Staff {
        uint staffId;
        address staff;
        string staffName;
        string staffPic;
        string staffDescription;
    }

    struct Gossip {
        address colleague;
        string comment;
    }
    struct Appraise {
        address colleague;
        string comment;
    }
    struct Tag {
        address colleague;
        string comment;
    }

    Staff[] public Staffs;
    Gossip[] public Gossips;
    Appraise[] public Appraises;
    Tag[] public Tags;
    

    constructor() public {
        owner = msg.sender;
    }
    function kill() public {
        require(msg.sender == owner,"Not owner");
        selfdestruct(owner);
    }

    event AddStaff(
        address colleague,
        string staffName,
        string staffDescription
    );

    event AppraiseStaff(
        address colleague,
        string comment
    );

    event GossipStaff(
        address colleague,
        string comment
    );

    event TagStaff(
        address colleague,
        string comment
    );

        

    function RegisterStaff(address staff,string staffName,string staffPic, string staffDescription)
     public returns(uint) {
        uint initialLength = Staffs.length;

        Staffs.push(Staff({
            staffId : initialLength,
            staff: staff,
            staffName: staffName,
            staffPic: staffPic,
            staffDescription : staffDescription
        }));

        emit AddStaff(staff,staffName,staffDescription);
        assert(Staffs.length == initialLength + 1);
        return Staffs.length;
    }

    function AddGossip(address colleague, string comment) public returns(uint) {
        uint initialLength = Gossips.length;
      
        Gossips.push(Gossip({
            colleague: colleague,
            comment: comment
        }));
        
        emit GossipStaff(colleague,comment);
        assert(Gossips.length == initialLength + 1);
        return Gossips.length;
    }
    
    function AddAppraise(address colleague, string comment) public returns(uint) {
        uint initialLength = Appraises.length;
   
        Appraises.push(Appraise({
            colleague: colleague,
            comment: comment
        }));
        
        emit AppraiseStaff(colleague, comment);
        assert(Appraises.length == initialLength + 1);
        return Appraises.length;
    }

    function AddTag(address colleague, string comment) public returns(uint) {
        uint initialLength = Tags.length;
     
        Tags.push(Tag({
            colleague: colleague,
            comment: comment
        }));
        
        emit TagStaff(colleague, comment);
        assert(Appraises.length == initialLength + 1);
        return Appraises.length;
    }
    
    function getStaff(uint staffId) public view returns( uint, address, string,string, string) {
        return (
            Staffs[staffId].staffId,
            Staffs[staffId].staff,
            Staffs[staffId].staffName,
            Staffs[staffId].staffPic,
            Staffs[staffId].staffDescription
          
   
        );
    }
    
     
    function getStaffLength() public view returns( uint) {
        return Staffs.length;
    }


}