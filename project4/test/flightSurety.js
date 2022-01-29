var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');

contract("FLIGHT SURETY TESTS", async (accounts) => {

    var config;
    before("SETUP CONTRACT", async () => {
        config = await Test.Config(accounts);
        await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);
    });

    /****************************************************************************************/
    /* OPERATIONS AND SETTINGS                                                              */
    /****************************************************************************************/
    it("(MULTIPARTY) HAS CORRECT INITIAL ISOPERATIONAL() VALUE", async function () {
        let status = await config.flightSuretyData.isOperational.call();
        assert.equal(status, true, "INCORRECT INITIAL OPERATING STATUS VALUE");
    });


    it("(MULTIPARTY) CAN BLOCK ACCESS TO setOperatingStatus() FOR NON-CONTRACT OWNER ACCOUNT", async function () {
        let accessDenied = false;
        try
        {
            await config.flightSuretyApp.setOperatingStatus(false, { from: config.testAddresses[2]});
        }
        catch(e) {
            accessDenied = true;
        }
        assert.equal(accessDenied, true, "ACCESS NOT RESTRICTED TO CONTRACT OWNER");
    });


    it("(MULTIPARTY) CAN ALLOW ACCESS TO setOperatingStatus() FOR CONTRACT OWNER ACCOUNT", async function () {
        let accessDenied = false;
        try 
        {
            await config.flightSuretyApp.setOperatingStatus(false, { from: config.owner });
        }
        catch(e) {
            accessDenied = true;
        }
        assert.equal(accessDenied, false, "ACCESS NOT RESTRICTED TO CONTRACT OWNER");
    });


    // it("(MULTIPARTY) CAN BLOCK ACCESS TO FUNCTIONS USING REQUIREISOPERATIONAL WHEN OPERATING STATUS IS FALSE", async function () {

    //     await config.flightSuretyApp.setOperatingStatus(false);

    //     let reverted = false;
    //     try 
    //     {
    //         await config.flightSurety.setTestingMode(true);
    //     }
    //     catch(e) {
    //         reverted = true;
    //     }
    //     assert.equal(reverted, true, "ACCESS NOT BLOCKED FOR REQUIREISOPERATIONAL");      

    //     // Set it back for other tests to work
    //     await config.flightSuretyData.setOperatingStatus(true);

    // });

    
    it("ONLY CONTROLLERS CAN REGISTER NEW AIRLINES", async () => {    
        let newAirlineName = "Air 2";
        let newAirlineAddress = accounts[2];
        try {
            await config.flightSuretyApp.registerAirline(newAirlineName, newAirlineAddress, {from: config.owner});
        }
        catch(e) {
            console.log("DIDN'T WORK")
        }
        let result = await config.flightSuretyApp.isRegistered.call(newAirlineAddress);
        assert.equal(result, true, "CONTROLLERS SHOULD BE ABLE TO REGISTER NEW AIRLINES");
    });    


    it("ONLY CONTROLLERS CAN REGISTER NEW AIRLINES 2", async () => {    
        let newAirlineAddress = accounts[2];
        let newAirlineName2 = "Air 3";
        let newAirlineAddress2 = accounts[3];
        try {
            await config.flightSuretyApp.registerAirline(newAirlineName2, newAirlineAddress2, {from: newAirlineAddress});
        }
        catch(e) {
            console.log("DIDN'T WORK")
        }
        let result = await config.flightSuretyApp.isRegistered.call(newAirlineAddress2);

        assert.equal(result, true, "CONTROLLERS SHOULD BE ABLE TO REGISTER NEW AIRLINES");
    });
 

    // it("NOT ENOUGH FUNDS TO BECOME PARTICIPANT", async () => {    
    //     try {
    //         await config.flightSuretyApp.registerAirline(newAirlineName2, newAirlineAddress2, {from: newAirlineAddress});
    //     }
    //     catch(e) {
    //         console.log("DIDN'T WORK")
    //     }
    //     let result = await config.flightSuretyApp.isRegistered.call(newAirlineAddress2);

    //     assert.equal(result, true, "CONTROLLERS SHOULD BE ABLE TO REGISTER NEW AIRLINES");
    // });


});