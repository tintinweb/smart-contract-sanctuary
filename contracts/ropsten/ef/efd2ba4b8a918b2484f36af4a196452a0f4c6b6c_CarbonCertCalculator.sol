pragma solidity ^0.4.24;

contract CarbonCertCalculator{

  struct Calc {
    string project;
    string memo;
    uint256 ciDischarge;
    uint256 ciGrid;
    uint256 gMT;
    uint256 eRatio;
    uint256 EER;
    bool success;
    bool issued;
  }

  string public project; // e.f. "CARB.LCFS"
  Calc[] public Calcs;   // list of calculations done
  uint256[] settings;    // any system settings required

  uint256 ciDischarged = 9355; // CIdis = 93.55
  uint256 ciGrid       = 3092; // CIgrid = 30.92941176
  uint256 gMT = 1;             // gMT = 10^-6
  uint256 eRatio = 36;         // E_Ratio = 3.6
  uint256 EER = 34;            // EER = 3.4
  uint256 multiplier = 100000000; 

  event CarbonCertCalculation(string project, string memo, uint256 result, uint256 discharged, uint256 generated, uint256 timestamp);

  //
  // Contract Constructure - assign project name + settings(if any)
  //
  constructor(string _project, uint256[] _settings) public {
    require(bytes(_project).length > 0);
    require(_settings.length == 5,"Cannot have more or less than 5 settings values");
    project = _project;   
    for (uint i=0; i<_settings.length; i++) {
      settings.push(_settings[i]);
    }
  }

  //
  // Execute a Calcuilation on given discharge, generation data set taken at given hour  
  //
  function executeCalc(string _project, uint256 _hour, uint256 _discharged, uint _generated) public returns(uint256) {
    bytes memory p1 = bytes(_project);
    bytes memory p2 = bytes(project);
    require(keccak256(p1) == keccak256(p2), "Invalid project passed as parameter");   
    require(_hour < 24, "hour must be in range of 0 to 23");

    uint256 kwh1 = 0;
    uint256 kwh2 = 0;
    uint256 gridCredits = 0;
    uint256 solarCredits = 0;
    uint256 total = 0;

    // TODO - lookup ci values from Carbon Intensity contract
    if (_discharged <= _generated) {
       kwh1 = _discharged;
       kwh2 = 0;
       gridCredits = 0;
       solarCredits = (ciDischarged - 0) * gMT * eRatio * EER * kwh1; 
    } else {
       kwh1 = _generated;
       kwh2 = (_discharged - _generated);
       solarCredits = (ciDischarged - 0)      * gMT * eRatio * EER * kwh1; 
       gridCredits =  (ciDischarged - ciGrid) * gMT * eRatio * EER * kwh2;
    }
    total = (solarCredits + gridCredits)/multiplier;

    // raise an event to notify wany listeners about this calc.
    emit CarbonCertCalculation(project, "Calculated new Cert amount ", total, _discharged, _generated,  block.timestamp);
    return total;
  }
}