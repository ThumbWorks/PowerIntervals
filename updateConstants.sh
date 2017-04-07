echo "checking if distribution"
echo $CONFIGURATION
if [[ "$CONFIGURATION" == "Release" ]]; then
  echo "It is dist"
  KEYCHAINS=`security list-keychains`

  if ! [[ "$KEYCHAINS" =~ "PowerIntervals.keychain" ]]; then
    open PowerIntervals.keychain
  fi

  SMOOCH_TOKEN=`security find-generic-password -a roderic -s Smooch -w`
  echo "SMOOCH $SMOOCH_TOKEN"
  perl -p -i -e "s/SMOOCH_TOKEN_PLACEHOLDER/$SMOOCH_TOKEN/g" "$SRCROOT/Constants.swift"

  STRAVA_SECRET=`security find-generic-password -a roderic -s StravaSecret -w`
  echo "Strava secret $STRAVA_SECRET"
  perl -p -i -e "s/STRAVA_SECRET_PLACEHOLDER/$STRAVA_SECRET/g" "$SRCROOT/Constants.swift"

  STRAVA_CLIENTID=`security find-generic-password -a roderic -s StravaClientID -w`
  echo "Strava clientID $STRAVA_CLIENTID"
  perl -p -i -e "s/STRAVA_CLIENTID_PLACEHOLDER/$STRAVA_CLIENTID/g" "$SRCROOT/Constants.swift"

  MIXPANEL_TOKEN=`security find-generic-password -a roderic -s Mixpanel -w`
  echo "Mixpanel Token $MIXPANEL_TOKEN"
  perl -p -i -e "s/MIXPANEL_TOKEN_PLACEHOLDER/$MIXPANEL_TOKEN/g" "$SRCROOT/Constants.swift"
fi

echo "Done with that script"
