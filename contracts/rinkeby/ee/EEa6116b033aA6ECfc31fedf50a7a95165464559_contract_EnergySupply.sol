/**
 *Submitted for verification at Etherscan.io on 2021-08-31
*/

pragma solidity >=0.4.21 <0.6.0 ;

contract contract_EnergySupply{
    
    
    struct Sgp_statistic_ente_stat{
        
         string cdate;      //yyyymmdd
         string name;
         uint value;
         string unit;
         uint category;
         string region;
         uint energyType;
         string industry;
         string industry_name;
        
    }
    
    struct Sgp_full_statistic{

        string type_name;
        uint value;
        string unit;
        uint category;
        string typeKeyId;   //equal to 'type'
        string cdate;       //yyyymmdd
        string region;
        string region_name;
        
    }
    
    struct Sgp_statistic_ente{
        

        string ente_id;
        string statisticTime; //yyyy-mm-dd
        uint datetype;
        uint value;
        string unit;
        uint energyType;
        uint category;
        string region_code;
        string ente_name;
        uint is_key_ente;
        string industry_code;
        
    }
    
    

    
    
    //两个事件监听

    event AddSgp_statistic_ente_stat(
        string cdate,
        string name,
        uint value,
        string unit,
        uint category,
        string region,
        uint energyType
        );
    
    event AddSgp_statistic_ente_stat_industry(
        string industry,
        string industry_name
        );
    
    function add_Sgp_statistic_ente_stat(
                                        string memory _cdate,
                                        string memory _name,
                                        uint _value,
                                        string memory _unit,
                                        uint _category,
                                        string memory _region,
                                        uint _energyType,
                                        string memory _industry,
                                        string memory _industry_name
                                        )
    public {
            
            Sgp_statistic_ente_stat memory item;
            
            item.cdate = _cdate;
            item.name = _name;
            item.value = _value;
            item.unit = _unit;
            item.category = _category;
            item.region = _region;
            item.energyType = _energyType;
            item.industry = _industry;
            item.industry_name = _industry_name;
            
            
            emit AddSgp_statistic_ente_stat_industry(_industry,_industry_name);
            emit AddSgp_statistic_ente_stat(_cdate,_name,_value,_unit,_category,_region,_energyType);
            
            
        
    }
    
    
    
    event AddSgp_full_statistic(
        string type_name,
        uint value,
        string unit,
        uint category,
        string typeKeyId,   //equal to 'type'
        string cdate,      //yyyymmdd
        string region,
        string region_name
    );
    
    function add_Sgp_full_statistic(
        string memory _type_name,
        uint _value,
        string memory _unit,
        uint _category,
        string memory _typeKeyId,   //equal to 'type'
        string memory _cdate,      //yyyymmdd
        string memory _region,
        string memory _region_name
    )
    public {
        
        Sgp_full_statistic memory item;
        item.type_name = _type_name;
        item.value = _value;
        item.unit = _unit;
        item.category = _category;
        item.typeKeyId = _typeKeyId;
        item.cdate = _cdate;
        item.region = _region;
        item.region_name = _region_name;
        
        emit AddSgp_full_statistic(_type_name,_value,_unit,_category,_typeKeyId,_cdate,_region,_region_name);
        
        
    }
    
    
    event AddSgp_statistic_ente(
        
        string statisticTime, //yyyy-mm-dd
        uint datetype,
        uint value,
        string unit,
        uint energyType,
        uint category,
        string region_code,
        
        uint is_key_ente
    );
    
    event AddEnte(
        string ente_id,
        string ente_name,
        string industry_code
    );
    
    
    function add_Sgp_statistic_ente(
        string memory _ente_id,
        string memory _statisticTime, //yyyy-mm-dd
        uint _datetype,
        uint _value,
        string memory _unit,
        uint _energyType,
        uint _category,
        string memory _region_code,
        string memory _ente_name,
        uint _is_key_ente,
        string memory _industry_code
        
        )
        
        
    public{
        
        Sgp_statistic_ente memory item;
        
        item.ente_id = _ente_id;
        item.statisticTime = _statisticTime;
        item.datetype = _datetype;
        item.value = _value;
        item.unit = _unit;
        item.energyType = _energyType;
        item.category = _category;
        item.region_code = _region_code;
        item.ente_name = _ente_name;
        item.is_key_ente = _is_key_ente;
        
        emit AddSgp_statistic_ente(
           
            _statisticTime, //yyyy-mm-dd
            _datetype,
            _value,
            _unit,
            _energyType,
            _category,
            _region_code,
            
            _is_key_ente
        );
        emit AddEnte( _ente_id,_ente_name,_industry_code);
        
    }
    
    
    
    
    
}