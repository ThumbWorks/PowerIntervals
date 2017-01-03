//
//  WFBikeTrainerDelegate.h
//  WFConnector
//
//  Created by Michael Moore on 8/18/12.
//  Copyright (c) 2012 Wahoo Fitness. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WFConnector/_WFBikeTrainerDelegate.h>


/**
 * Provides the interface for callback methods used by the WFBikePowerConnection.
 *
 * This delegate handles callbacks for commands according to the Wahoo-specific
 * Bike Trainer Profile.  For commands used by CSC Profile devices please see
 * the WFBikePowerDelegate.
 */
@protocol WFBikeTrainerDelegate <_WFBikeTrainerDelegate>

@optional

/**
 * Invoked when a response to the Set Trainer Mode command is received.
 *
 * @param cpmConn The WFBikePowerConnection instance.
 * @param eMode The WFBikeTrainerMode_t specified in the command.
 * @param params An NSDictionary instance containing changed parameters associated
 *               with the current mode.
 * @param info Structure containing info regarding the control point command (eg status)
 */
- (void)cpmConnection:(WFBikePowerConnection*)cpmConn didSetTrainerMode:(WFBikeTrainerMode_t)eMode params:(NSDictionary*)params info:(WFBikeTrainerDelegateInfo_t)info;
- (void)cpmConnection:(WFBikePowerConnection*)cpmConn didSetTrainerMode:(WFBikeTrainerMode_t)eMode status:(UCHAR)ucStatus __deprecated_msg("Use cpmConnection:didSetTrainerMode:params:info:");


/**
 * Invoked when a response to the Set Trainer Grade command is received.
 *
 * @param cpmConn The WFBikePowerConnection instance.
 * @param grade The new trainer grade.
 * @param info Structure containing info regarding the control point command (eg status)
 */
- (void)cpmConnection:(WFBikePowerConnection*)cpmConn didSetTrainerGrade:(float)grade info:(WFBikeTrainerDelegateInfo_t)info;
- (void)cpmConnection:(WFBikePowerConnection*)cpmConn didSetTrainerGrade:(UCHAR)ucStatus __deprecated_msg("Use cpmConnection:didSetTrainerGrade:info:");


/**
 * Invoked when a response to the Set Trainer Rolling Resistance command is received.
 *
 * @param cpmConn The WFBikePowerConnection instance.
 * @param rollingResistance The new rolling resistance.
 * @param info Structure containing info regarding the control point command (eg status)
 */
- (void)cpmConnection:(WFBikePowerConnection*)cpmConn didSetTrainerRollingResistance:(float)rollingResistance info:(WFBikeTrainerDelegateInfo_t)info;
- (void)cpmConnection:(WFBikePowerConnection*)cpmConn didSetTrainerRollingResistance:(UCHAR)ucStatus __deprecated_msg("Use cpmConnection:didSetTrainerRollingResistance:info:");



/**
 * Invoked when a response to the Set Trainer Wind Resistance command is received.
 *
 * @param cpmConn The WFBikePowerConnection instance.
 * @param windResistance The new wind resistance.
 * @param info Structure containing info regarding the control point command (eg status)
 */
- (void)cpmConnection:(WFBikePowerConnection*)cpmConn didSetTrainerWindResistance:(float)windResistance info:(WFBikeTrainerDelegateInfo_t)info;
- (void)cpmConnection:(WFBikePowerConnection*)cpmConn didSetTrainerWindResistance:(UCHAR)ucStatus __deprecated_msg("Use cpmConnection:didSetTrainerWindResistance:info:");


/**
 * Invoked when a response to the Set Trainer Wind Speed command is received.
 *
 * @param cpmConn The WFBikePowerConnection instance.
 * @param windSpeed The new wind speed.
 * @param info Structure containing info regarding the control point command (eg status)
 */
- (void)cpmConnection:(WFBikePowerConnection*)cpmConn didSetTrainerWindSpeed:(float)windSpeed info:(WFBikeTrainerDelegateInfo_t)info;
- (void)cpmConnection:(WFBikePowerConnection*)cpmConn didSetTrainerWindSpeed:(UCHAR)ucStatus __deprecated_msg("Use cpmConnection:didSetTrainerWindSpeed:info:");


/**
 * Invoked when a response to the Set Trainer Wheel Circumference command is received.
 *
 * @param cpmConn The WFBikePowerConnection instance.
 * @param wheelCircumference The new wheel circumference.
 * @param info Structure containing info regarding the control point command (eg status)
 */
- (void)cpmConnection:(WFBikePowerConnection*)cpmConn didSetTrainerWheelCircumference:(USHORT)wheelCircumference info:(WFBikeTrainerDelegateInfo_t)info;
- (void)cpmConnection:(WFBikePowerConnection*)cpmConn didSetTrainerWheelCircumference:(UCHAR)ucStatus __deprecated_msg("Use cpmConnection:didSetTrainerWindSpeed:info:");


/**
 * Invoked when a response to the Read Trainer Mode command is received.
 *
 * @param cpmConn The WFBikePowerConnection instance.
 * @param ucStatus The status of the command (0 is Success).
 * @param eMode If the command was successful, the current WFBikeTrainerMode_t.
 * @param params An NSDictionary instance containing any parameters associated
 * with the current mode.
 */
- (void)cpmConnection:(WFBikePowerConnection*)cpmConn didReceiveTrainerReadModeResponse:(WFBikeTrainerMode_t)eMode params:(NSDictionary*)params info:(WFBikeTrainerDelegateInfo_t)info;
- (void)cpmConnection:(WFBikePowerConnection*)cpmConn didReceiveTrainerReadModeResponse:(UCHAR)ucStatus mode:(WFBikeTrainerMode_t)eMode params:(NSDictionary*)params __deprecated_msg("Use cpmConnection:didReceiveTrainerReadModeResponse:params:info:");



- (void)cpmConnection:(WFBikePowerConnection*)cpmConn didReceiveTrainerReadModeResponse:(UCHAR)ucStatus mode:(WFBikeTrainerMode_t)eMode __attribute__((unavailable("Use cpmConnection:didReceiveTrainerReadModeResponse:mode:params")));

/**
 * Invoked when a response to the Trainer Request ANT Connection command is received.
 *
 * @param cpmConn The WFBikePowerConnection instance.
 * @param ucStatus The command status code (0 for Success).
 */
- (void)cpmConnection:(WFBikePowerConnection*)cpmConn didReceiveTrainerRequestAntConnectionResponse:(UCHAR)ucStatus;


/**
 * Invoked when a response to the Trainer Init Spindown command is received.
 *
 * @param cpmConn The WFBikePowerConnection instance.
 * @param ucStatus The command status code (0 for Success).
 */
- (void)cpmConnection:(WFBikePowerConnection*)cpmConn didReceiveTrainerInitSpindownResponseWithInfo:(WFBikeTrainerDelegateInfo_t)info __deprecated_msg("Use WFBikeTrainerSpindownCalibratorDelegate class to receive spindown progress callbacks");
- (void)cpmConnection:(WFBikePowerConnection*)cpmConn didReceiveTrainerInitSpindownResponse:(UCHAR)ucStatus __deprecated_msg("Use WFBikeTrainerSpindownCalibratorDelegate class to receive spindown progress callbacks");



/**
 * Invoked when a Trainer Spindown Result is received.
 *
 * @param cpmConn The WFBikePowerConnection instance.
 * @param spindownTime The spindown time value.
 * @param spindownTemperature The spindown temperature value.
 * @param spindownOffset The zero offset calibration
 */
- (void)cpmConnection:(WFBikePowerConnection*)cpmConn didReceiveTrainerSpindownResult:(float)spindownTime temperature:(float)spindownTemperature offset:(USHORT)spindownOffset __deprecated_msg("Use WFBikeTrainerSpindownCalibratorDelegate class to receive spindown progress callbacks");


/**
 * Invoked when a Kurt InRide Trainer Spindown Result is received.
 *
 * @param cpmConn The WFBikePowerConnection instance.
 * @param ulSpindownPeriod The spindown period, in microseconds.
 */
- (void)cpmConnection:(WFBikePowerConnection*)cpmConn didReceiveKurtSpindownResult:(ULONG)ulSpindownPeriod;


- (void)cpmConnection:(WFBikePowerConnection*)cpmConn didReceiveKurtSetProFlywheelEnabled:(BOOL) proFlywheelEnabled spindownEnabled:(BOOL) spindownEnabled response:(BOOL)bSuccess;


@end
