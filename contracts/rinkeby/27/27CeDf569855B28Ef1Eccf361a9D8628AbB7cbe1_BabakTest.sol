pragma solidity 0.8.0;

contract BabakTest{
    uint256 a= 14;
    bool flag= true;
    int256 b = 14;
    string s = "hello";
    address bob = 0x0e2CF851A13C172c14db4AD9c792dA87c02Ec192;
    bytes32 ss = "dog";
    // this will initialize as zerr
    uint256 test;
    struct people {
        uint256 age;
        string name;
    }
    
    mapping(string=> uint256) public name_to_age;
    people public teacher = people ({age:23,name:"davood"});
    people[] public array_of_human;

    function store (uint256 input) public{
        test = input;
    }
    // function name (type input ) public pure/view  return( outputtype)
    function print () public view returns(uint256){
        return test;
    }


    function add_peson (string memory name_, uint256 age_ ) public{

        people memory temp = people({age:age_, name:name_});
        array_of_human.push(temp);
        name_to_age[name_] = age_;
    }

}