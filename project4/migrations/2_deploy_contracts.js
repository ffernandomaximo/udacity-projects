const FlightSuretyApp = artifacts.require("FlightSuretyApp");
const FlightSuretyData = artifacts.require("FlightSuretyData");
const DateLib = artifacts.require("DateLib");
const RoleLib = artifacts.require("RoleLib");
const Ownable = artifacts.require("Ownable");

const fs = require('fs');

module.exports = function (deployer) {

    deployer.deploy(Ownable);    
    deployer.deploy(RoleLib);
    deployer.deploy(DateLib);
    deployer.link(DateLib, FlightSuretyData);
    deployer.deploy(FlightSuretyData)
    .then(() => {
        return deployer.deploy(FlightSuretyApp, FlightSuretyData.address)
                .then(() => {
                    let config = {
                        localhost: {
                            url: 'http://localhost:7545',
                            dataAddress: FlightSuretyData.address,
                            appAddress: FlightSuretyApp.address
                        }
                    }
                    fs.writeFileSync(__dirname + '/../src/dapp/config.json',JSON.stringify(config, null, '\t'), 'utf-8');
                    fs.writeFileSync(__dirname + '/../src/server/config.json',JSON.stringify(config, null, '\t'), 'utf-8');
                });
    });
};