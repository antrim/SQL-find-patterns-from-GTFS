Files found from the following sources:

TZ world map:

  http://efele.net/maps/tz/world/

TZ world map including territorial waters:

  https://github.com/gregology/territorial-timezones

  "World timezones including territorial waters

  efele.net/tz have done a wonderful job curating world timezones. However the
  maps used only include land. Harbours, coastal waters, and large lakes are
  considered international waters"

  Note: after import to postgis, make sure to use st_makevalid() to normalize the
  shapes. Ed 2016-08-31
